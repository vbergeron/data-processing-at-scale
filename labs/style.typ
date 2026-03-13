#let lab-theme(
  title: [],
  session: [],
  format: [],
  tools: [],
  body,
) = {
  set document(title: title)
  set page(
    paper: "a4",
    margin: (x: 2.5cm, y: 2cm),
    header: context {
      if counter(page).get().first() > 1 {
        set text(size: 9pt, fill: luma(120))
        grid(
          columns: (1fr, 1fr),
          align(left, emph(title)),
          align(right, [Data Processing at Scale]),
        )
        v(2pt)
        line(length: 100%, stroke: 0.4pt + luma(200))
      }
    },
    footer: context {
      set text(size: 9pt, fill: luma(120))
      align(center, counter(page).display("1 / 1", both: true))
    },
  )
  set text(font: "New Computer Modern", size: 11pt)
  set par(justify: true)
  set heading(numbering: "1.1.")
  show heading.where(level: 1): it => {
    v(0.5em)
    text(fill: rgb("#E06C75"), it)
    v(0.3em)
  }
  show heading.where(level: 2): it => {
    v(0.4em)
    text(fill: rgb("#E06C75").darken(20%), it)
    v(0.2em)
  }
  show heading.where(level: 3): it => {
    v(0.3em)
    text(fill: luma(60), it)
    v(0.1em)
  }

  // Title block
  {
    set align(center)
    v(1cm)
    text(size: 20pt, weight: "bold", fill: rgb("#E06C75"), title)
    v(0.6cm)
    text(size: 11pt, fill: luma(80))[
      #session \
      #format \
      *Tools:* #tools
    ]
    v(0.4cm)
    line(length: 60%, stroke: 1pt + rgb("#E06C75"))
    v(1cm)
  }

  body
}
