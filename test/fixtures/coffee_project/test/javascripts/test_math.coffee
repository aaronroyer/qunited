module 'Math'

test 'Addition works', () ->
  expect 2
  equal 1 + 1, 2, 'One plus one does equal two'
  equal 2 + 2, 4, 'Two plus two does equal four'

test 'Subtraction works', () ->
  expect 1
  equal 2 - 1, 1, 'Two minus one equals one'
