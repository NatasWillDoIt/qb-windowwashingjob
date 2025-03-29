let windowsTotal = 0
let windowsCompleted = 0

$(() => {
  window.addEventListener("message", (event) => {
    const data = event.data

    if (data.action === "showUI") {
      $("#window-washing-container").fadeIn(500)
      updateProgress(data.progress)
      updateTeam(data.team)
    } else if (data.action === "hideUI") {
      $("#window-washing-container").fadeOut(500)
    } else if (data.action === "updateProgress") {
      updateProgress(data.progress)
    } else if (data.action === "updateTeam") {
      addTeamMember(data.newMember)
    }
  })

  // Close button
  $("#close-ui").click(() => {
    $.post("https://qb-windowwashing/closeUI", JSON.stringify({}))
  })

  // Add quit job button functionality
  $("#quit-job").click(() => {
    $.post("https://qb-windowwashing/quitJob", JSON.stringify({}))
  })

  // Add NUI callback for quit job
  RegisterNUICallback("quitJob", () => {
    $.post("https://qb-windowwashing/quitJob", JSON.stringify({}))
  })
})

function updateProgress(progress) {
  $("#progress-text").text(progress)

  // Extract numbers from progress string (e.g. "5/10")
  const progressParts = progress.split("/")
  if (progressParts.length === 2) {
    windowsCompleted = Number.parseInt(progressParts[0])
    windowsTotal = Number.parseInt(progressParts[1])

    // Update progress bar
    const percentage = (windowsCompleted / windowsTotal) * 100
    $("#progress-bar").css("width", percentage + "%")
  }
}

function updateTeam(team) {
  // Clear current team list
  $("#team-list").empty()

  // Add each team member
  team.forEach((member) => {
    $("#team-list").append(`<li>${member}</li>`)
  })
}

function addTeamMember(member) {
  $("#team-list").append(`<li>${member}</li>`)
}

