(function () {
  var activeGrid = document.getElementById("active-grid");
  var activeEmpty = document.getElementById("active-empty");
  if (activeGrid) {
    fetch("/api/prs")
      .then(function (r) { return r.json(); })
      .then(function (prs) {
        var active = prs.filter(function (pr) { return pr.state === "open"; });
        if (!active.length) {
          if (activeEmpty) activeEmpty.style.display = "block";
          return;
        }
        activeGrid.innerHTML = active.slice(0, 8).map(function (pr) {
          var date = new Date(pr.updated).toLocaleDateString("en-US", {
            month: "short", day: "numeric", year: "numeric"
          });
          return '<a href="' + pr.url + '" target="_blank" rel="noopener noreferrer" class="card card-link">'
            + '<div class="oss-meta"><span>' + pr.repo + '</span><span>Open</span></div>'
            + '<h3>' + pr.title + '</h3>'
            + '<p class="text-sm" style="margin-top:auto">' + date + ' · ' + pr.comments + ' comments</p>'
            + '</a>';
        }).join("");
      })
      .catch(function () {
        if (activeEmpty) activeEmpty.style.display = "block";
      });
  }

  var listEl = document.getElementById("merged-list");
  var mergedEmpty = document.getElementById("merged-empty");
  if (listEl) {
    fetch("/api/merged")
      .then(function (r) { return r.json(); })
      .then(function (data) {
        var prs = data.prs || [];
        if (!prs.length) {
          if (mergedEmpty) mergedEmpty.style.display = "block";
          return;
        }
        listEl.innerHTML = prs.slice(0, 12).map(function (pr) {
          var date = new Date(pr.merged).toLocaleDateString("en-US", {
            month: "short", day: "numeric", year: "numeric"
          });
          return '<a href="' + pr.url + '" target="_blank" rel="noopener noreferrer" class="timeline-item">'
            + '<span class="timeline-date mono">' + date + '</span>'
            + '<span class="timeline-dot"></span>'
            + '<div class="timeline-content">'
            + '<span class="timeline-repo">' + pr.repo + '</span>'
            + '<span class="timeline-title">' + pr.title + '</span>'
            + '</div>'
            + '</a>';
        }).join("");
      })
      .catch(function () {
        if (mergedEmpty) mergedEmpty.style.display = "block";
      });
  }
})();
