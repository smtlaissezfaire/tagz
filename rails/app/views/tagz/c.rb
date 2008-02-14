@bar = 42

content_for :foo do
  div_(:id => :foo){ 'foo' }
end

em_{
  div_{ "this here is content for the layout" }
}
