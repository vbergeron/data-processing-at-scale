#import "@preview/touying:0.6.3": *
#import themes.metropolis: *
#import "@preview/tiaoma:0.3.0"

#let base-url = "https://vbergeron.github.io/data-processing-at-scale/"

#let hero(body) = {
  align(center + horizon, text(size: 28pt, body))
}

#let dpas-theme(title: [], day: [], slug: "", lab: (), next: "", body) = {
  show: metropolis-theme.with(
    aspect-ratio: "16-9",
    footer: self => self.info.institution,
    config-colors(
      primary: rgb("#B5303B"),
      primary-light: rgb("#d4777e"),
    ),
    config-info(
      title: title,
      subtitle: [Data Processing at Scale],
      date: datetime.today(),
      institution: [Data Processing at Scale — #day],
    ),
  )
  title-slide()

  if slug != "" {
    let slide-url = base-url + slug + ".pdf"
    slide[
      #align(center + horizon)[
        #grid(
          columns: (1fr, 1fr),
          column-gutter: 2cm,
          align: center,
          [
            #tiaoma.qrcode(base-url, width: 4cm)
            #v(0.4em)
            #text(size: 12pt, weight: "bold")[Course website]
            #v(0.2em)
            #text(size: 10pt, fill: luma(120))[#link(base-url)[#base-url]]
          ],
          [
            #tiaoma.qrcode(slide-url, width: 4cm)
            #v(0.4em)
            #text(size: 12pt, weight: "bold")[This presentation]
            #v(0.2em)
            #text(size: 10pt, fill: luma(120))[#link(slide-url)[#slide-url]]
          ],
        )
      ]
    ]
  }

  body

  // Normalize lab to an array
  let labs = if type(lab) == str and lab != "" { (lab,) } else if type(lab) == array { lab } else { () }

  if labs.len() == 1 {
    let url = base-url + "lab-" + labs.at(0) + ".pdf"
    slide[
      #align(center + horizon)[
        #text(size: 24pt, weight: "bold")[Lab]
        #v(1em)
        #tiaoma.qrcode(url, width: 5cm)
        #v(0.5em)
        #text(size: 14pt, fill: luma(120))[#link(url)[#url]]
      ]
    ]
  } else if labs.len() > 1 {
    slide[
      #align(center + horizon)[
        #text(size: 24pt, weight: "bold")[Labs]
        #v(1em)
        #grid(
          columns: labs.len() * (1fr,),
          column-gutter: 2cm,
          align: center,
          ..labs.map(l => {
            let url = base-url + "lab-" + l + ".pdf"
            [
              #tiaoma.qrcode(url, width: 4cm)
              #v(0.4em)
              #text(size: 14pt, fill: luma(120))[#link(url)[#l]]
            ]
          })
        )
      ]
    ]
  }

  if next != "" {
    let url = base-url + next + ".pdf"
    slide[
      #align(center + horizon)[
        #text(size: 24pt, weight: "bold")[Next]
        #v(1em)
        #tiaoma.qrcode(url, width: 5cm)
        #v(0.5em)
        #text(size: 14pt, fill: luma(120))[#link(url)[#url]]
      ]
    ]
  }
}
