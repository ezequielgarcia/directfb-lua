local canvas = require 'canvas'

canvas:attrColor(0xff, 0, 0, 0xff)
canvas:drawRect('fill', 100, 100, 60, 60)

canvas:attrColor(0, 0xff, 0, 0xff)
canvas:drawRect('frame', 200, 100, 60, 60)

canvas:attrFont('DejaVuSans', 20)
canvas:attrColor('blue')
canvas:drawText(50,50, 'Canvas module, a bit moronic')

canvas:attrFont('DejaVuSans', 50)
canvas:attrColor('white')
canvas:drawText(50,500, 'Canvas module, a bit moronic')

print(canvas:measureText('Very very large large text'))
print(canvas:measureText('Very'))

canvas:drawLine(0,0,canvas:attrSize())

canvas:flush()
