/* global Elm */

const debounce = require('debounce')
const jq = require('jq-web/jq.wasm.min.js')

const target = document.querySelector('main')

const app = Elm.Main.embed(target, {
  input: localStorage.getItem('input') || '',
  filter: localStorage.getItem('filters') || '.'
})

app.ports.applyfilter.subscribe(debounce(applyfilter, 600))

function applyfilter ([input, filter]) {
  if (input === '') {
    app.ports.send('')
    return
  }

  try {
    let res = jq.raw(input, filter)
    app.ports.gotresult.send(res)
  } catch (e) {
    if (typeof e === 'string' && e.slice(0, 5) === 'abort') {
      setTimeout(applyfilter, 500, [input, filter])
      return
    }

    app.ports.goterror.send(e.message)
  }

  localStorage.setItem('filters', filter)
  localStorage.setItem('input', input)
}
