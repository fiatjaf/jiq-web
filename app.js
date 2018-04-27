/* global Elm, jq */

const debounce = require('debounce')

const target = document.querySelector('main')

const app = Elm.Main.embed(target, {
  input: localStorage.getItem('input') || '',
  filter: localStorage.getItem('filter') || '.'
})

app.ports.applyfilter.subscribe(debounce(applyfilter, 1000))

function applyfilter ([input, filter]) {
  if (input === '') {
    app.ports.gotresult.send('')
    return
  }

  jq.promised.raw(input, filter)
    .then(res => app.ports.gotresult.send(res))
    .catch(e => {
      if (typeof e === 'string' && e.slice(0, 5) === 'abort') {
        setTimeout(applyfilter, 500, [input, filter])
        return
      }
      console.error(e)
      app.ports.goterror.send(e.message)
    })

  localStorage.setItem('filter', filter)
  localStorage.setItem('input', input)
}
