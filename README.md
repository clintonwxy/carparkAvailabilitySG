# carparkAvailabilitySG
Shiny web app showcasing real-time availability of car parks in Singapore. This is still a work in progress and I am still improving the features and UI/UX of this shiny app! Do let me know if you have any suggestions! The developmental version of the app can be found [here](https://clintonwxy.shinyapps.io/carparkavailabilitysg/)!.

## Description
<p style="text-align: center;">
<img src="https://raw.githubusercontent.com/clintonwxy/carparkAvailabilitySG/master/images/image1.png" style="width:300px;">
</p>

[carparkAvailabilitySG](https://clintonwxy.shinyapps.io/carparkavailabilitysg/) is a real-time web app that showcases the current available carpark lots around Singapore. It is built entirely in *R* and *Shiny*, supported by [datagovsgR](https://cran.r-project.org/web/packages/datagovsgR/index.html), an R package which I had built to pull real time information from the [data.gov.sg](https://data.gov.sg/developer) API. This web application allows the user to search for a particular HDB carpark lot, and obtain information about it. Besides availability, information such as the carpark type, if it has free parking, if it is short-term parking and if it allows for night parking.

## Work in Progress
| Target | Completed | Remarks |
|:----------:| :------: | ------------------------------------------------------------|
| Search bar | :heavy_check_mark: | Adding search bar, allowing user to search for a particular carpark |
| Zoom to search | :heavy_check_mark: | Zoom to search input and show popup |
| Legend | :heavy_check_mark: | Toggle option to show legend |
| Refresh | | Button to pull latest carpark information, incomplete |
| Full Info | :heavy_check_mark: | Toggle option to show full carpark information |
| Nearby | | Upon clicking on one carpark, show availability of the nearest next 3 carparks |
| Improve UI/UX | | Change from the default Shiny theme |

## Feedback
Do let me know if you have any feedback or improvements!
