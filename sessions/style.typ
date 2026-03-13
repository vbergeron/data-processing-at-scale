#import "@preview/touying:0.6.3": *
#import themes.metropolis: *

#let dpas-theme(title: [], day: [], body) = {
  show: metropolis-theme.with(
    aspect-ratio: "16-9",
    footer: self => self.info.institution,
    config-colors(
      primary: rgb("#E06C75"),
      primary-light: rgb("#e8a5ab"),
    ),
    config-info(
      title: title,
      subtitle: [Data Processing at Scale],
      date: datetime.today(),
      institution: [Data Processing at Scale — #day],
    ),
  )
  title-slide()
  body
}
