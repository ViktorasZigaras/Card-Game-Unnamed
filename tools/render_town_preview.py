"""Static data-driven layout study; not a screenshot of Godot."""
from pathlib import Path
from io import BytesIO
import json,hashlib
from reportlab.pdfgen import canvas
from reportlab.lib.colors import HexColor
import fitz
root=Path(__file__).resolve().parents[1]
a=json.loads((root/'experiments/mapped_checks/initial_state.json').read_text())['state']
b=json.loads((root/'experiments/mapped/seed_7_manual/save.json').read_text())['state']
stream=BytesIO();c=canvas.Canvas(stream,pagesize=(1600,810));c.translate(0,810);c.scale(1,-1)
def rect(x,y,w,h,color,edge=None):
 c.setFillColor(HexColor(color));c.setStrokeColor(HexColor(edge or color));c.rect(x,y,w,h,fill=1,stroke=bool(edge))
def line(x,y,xx,yy,color,width):
 c.setStrokeColor(HexColor(color));c.setLineWidth(width);c.line(x,y,xx,yy)
def text(x,y,s,size=16,color='#e4d7ad'):
 c.saveState();c.translate(x,y);c.scale(1,-1);c.setFillColor(HexColor(color));c.setFont('Helvetica',size);c.drawString(0,0,s);c.restoreState()
def tree(x,y):
 rect(x-2,y,4,15,'#786042')
 for j in range(3):
  top=y-25+j*8;p=c.beginPath();p.moveTo(x,top);p.lineTo(x-13,top+18);p.lineTo(x+13,top+18);p.close();c.setFillColor(HexColor('#294d32' if j%2==0 else '#3e673c'));c.drawPath(p,fill=1,stroke=0)
def sprite(index,x,y,w,h):
 left=round(index%4*1774/4);top=round(index//4*887/2);sw=round((index%4+1)*1774/4)-left;sh=round((index//4+1)*887/2)-top
 scale=min(w/sw,h/sh);ix=x+(w-sw*scale)/2;iy=y+(h-sh*scale)/2
 c.saveState();p=c.beginPath();p.rect(ix,iy,sw*scale,sh*scale);c.clipPath(p,stroke=0)
 c.translate(ix-left*scale,iy-top*scale+887*scale);c.scale(1,-1);c.drawImage(str(root/'art/buildings.png'),0,0,width=1774*scale,height=887*scale,mask='auto');c.restoreState()
rect(0,0,1600,810,'#201f19');text(26,35,'TOWN - FIXED PLOTS, CHANGING USE',25)
text(26,63,'Reconstructed v0.909 - static study from real game states; roads are decorative',16,'#bdb58e')
colors={'urban':'#786b4b','forest':'#344e35','field':'#687146','wild':'#2e462e','special':'#6d6650'}
for ox,state,title in [(20,a,'Beginning - four outer plots still wild'),(815,b,'Later - converted land, Halls and sawmill')]:
 text(ox+8,104,title,20);px,py,w,h=ox+8,128,748,570;rect(px,py,w,h,'#34452e');sx,sy=(w-24)/5,(h-30)/3
 for y in [py+10+sy,py+10+sy*2]:line(px+20,y,px+w-20,y,'#98845a',6)
 line(px+12+sx,py+15,px+12+sx,py+h-15,'#98845a',5)
 for cell in state['town_map']['cells']:
  x,y=px+17+cell['column']*sx,py+14+cell['row']*sy;cw,ch=sx-10,sy-18;rect(x,y,cw,ch,colors[cell['terrain']],'#4c5538')
  if cell['vegetation']:
   for i in range(4):
    n=int.from_bytes(hashlib.sha256((cell['id']+str(i)).encode()).digest()[:2],'little');tx,ty=x+cw*(.16+n%69*.01),y+ch*(.28+(i%2)*.35)
    if cell['terrain'] in ['forest','wild']:tree(tx,ty)
    else:
     for j in range(3):line(tx+j*4,ty,tx+j*4-2,ty-9-j,'#9b9b52',2)
  bid=cell['building']
  if bid:
   v=state['buildings'][bid];index=1 if bid.startswith('hall_') or bid.startswith('hut_') and v['level']==2 else 0 if bid.startswith('hut_') else {'grain_farm':2,'lumber_camp':3,'carpenter':4,'small_sawmill':4,'marketplace':5,'chapel':6}.get(bid)
   if index is not None:sprite(index,x,y,cw,ch-20)
   label=bid.replace('_',' ').title()
  else:label=cell['id']+' - '+('Wild' if not cell['active'] else cell['terrain'].title())
  text(x+5,y+ch-4,label,12,{'blue':'#8ac1e9','red':'#ea9b85','gold':'#f0d879'}.get(state['buildings'].get(bid,{}).get('owner',''),'#e4d7ad'))
 if state.get('town',{}).get('wall_complete',False):
  c.setStrokeColor(HexColor('#b19765'));c.setLineWidth(3);c.rect(px+12+sx,py+9,sx*3,sy*2,fill=0,stroke=1)
 text(ox+8,728,'U1-U6, F1-F2, D1-D2, S1 and N1-N4 retain their addresses.',14,'#bdb58e')
text(28,774,'Motion in Godot: one window, saw, banner OR smoke effect per building - Gentle motion can be switched off',16)
c.save();doc=fitz.open(stream=stream.getvalue(),filetype='pdf');out=root/'docs/images';out.mkdir(exist_ok=True);doc[0].get_pixmap().save(out/'town_layout_0_909.png')
print(out/'town_layout_0_909.png')
