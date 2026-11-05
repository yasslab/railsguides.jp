// 細い画面（767px 未満）では、表の 1 列目を左に固定して残りを横にスクロールさせる。
// jQuery を使わない。以前の jQuery 1.7.2 版と同じ DOM の変化になるように書いている
(function() {
  function wrap(element, className) {
    var wrapper = document.createElement("div");
    wrapper.className = className;
    element.parentNode.insertBefore(wrapper, element);
    wrapper.appendChild(element);
  }

  function unwrap(element) {
    var parent = element.parentNode;
    if (!parent || parent === document.body) return;
    while (parent.firstChild) parent.parentNode.insertBefore(parent.firstChild, parent);
    parent.parentNode.removeChild(parent);
  }

  function ready() {
    var switched = false;
    document.querySelectorAll("table").forEach(function(table) {
      table.classList.add("responsive");
      wrap(table, "table-wrapper");
    });

    // jQuery の $(window).width() と同じく、スクロールバーを除いた幅で見る
    var updateTables = function() {
      var width = document.documentElement.clientWidth;
      if ((width < 767) && !switched ){
        switched = true;
        document.querySelectorAll("table.responsive").forEach(splitTable);
        return true;
      }
      else if (switched && (width > 767)) {
        switched = false;
        document.querySelectorAll("table.responsive").forEach(unsplitTable);
      }
    };

    window.addEventListener("load", updateTables);
    window.addEventListener("resize", updateTables);
  }

  function splitTable(original) {
    var copy = original.cloneNode(true);
    copy.querySelectorAll("td:not(:first-child), th:not(:first-child)").forEach(function(cell) {
      cell.style.display = "none";
    });
    copy.classList.remove("responsive");

    original.closest(".table-wrapper").appendChild(copy);
    wrap(copy, "pinned");
    wrap(original, "scrollable");
  }

  function unsplitTable(original) {
    original.closest(".table-wrapper").querySelectorAll(".pinned").forEach(function(pinned) {
      pinned.parentNode.removeChild(pinned);
    });
    unwrap(original);
  }

  if (document.readyState === "loading") {
    document.addEventListener("DOMContentLoaded", ready);
  } else {
    ready();
  }
})();
