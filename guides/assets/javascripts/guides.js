// ガイドの目次（ヘッダーのメニュー・小さい画面の目次の選択・「詳しく」のポップアップ）を動かす。
// jQuery を使わない。以前の jQuery 1.7.2 版と同じ DOM の変化になるように書いている
var guidesIndex = {
  bind: function() {
    var currentGuidePath = window.location.pathname;
    var currentGuide = currentGuidePath.substring(currentGuidePath.lastIndexOf("/")+1);

    // 小さい画面の目次: 今のガイドを選んだ状態にし、選び直したらそのガイドへ移る
    document.querySelectorAll(".guides-index-small").forEach(function(index) {
      index.addEventListener("change", function(e) {
        if (e.target.matches("select")) guidesIndex.navigate(e);
      });
      // jQuery の .val() と同じく、合う選択肢だけを選ぶ。合うものが無ければ、ブラウザは最初の選択肢を見せる
      // （select.value に入れると、合うものが無い時に空になってしまう）
      index.querySelectorAll("select option").forEach(function(option) {
        option.selected = option.value === currentGuide;
      });
    });

    // 「詳しく」のボタンで開閉し、ポップアップの外を押したら閉じる。
    // jQuery 版では、ボタンの処理の stopPropagation が外側の処理も止めていたので、1 つの処理の中で分ける
    document.addEventListener("click", function(e) {
      var element = e.target;
      // Defeat the older Safari bug:
      // http://www.quirksmode.org/js/events_properties.html
      if (element.nodeType === 3) element = element.parentNode;

      e.stopPropagation();
      if (element.closest(".more-info-button")) {
        guidesIndex.toggleMoreInfo();
        return;
      }

      // We've captured a click outside the popup
      if (!element.parentElement || !element.parentElement.closest(".more-info-container")) {
        document.querySelectorAll(".more-info-button").forEach(function(button) {
          var container = button.nextElementSibling;
          if (!container || !container.matches(".more-info-container")) return;
          container.querySelectorAll(".more-info-links").forEach(function(links) {
            links.classList.add("s-hidden");
            guidesIndex.unwrap(links);
          });
        });
      }
    });

    // ヘッダーの「ガイド目次」で目次を開閉する（リンク先へは移らない）
    var menu = document.getElementById("guidesMenu");
    if (menu) {
      menu.addEventListener("click", function(e) {
        e.preventDefault();
        e.stopPropagation();
        var guides = document.getElementById("guides");
        if (guides) guidesIndex.toggle(guides);
      });
    }
  },

  navigate: function(e) {
    window.location = e.target.value;
  },

  toggleMoreInfo: function() {
    var links = document.querySelectorAll(".more-info-links");
    var visible = Array.prototype.some.call(links, guidesIndex.isVisible);
    links.forEach(function(element) {
      if (visible) {
        element.classList.add("s-hidden");
        guidesIndex.unwrap(element);
      } else {
        var container = document.createElement("div");
        container.className = "more-info-container";
        element.parentNode.insertBefore(container, element);
        container.appendChild(element);
        element.classList.remove("s-hidden");
      }
    });
  },

  // 親の要素を外し、中身をその場に残す
  unwrap: function(element) {
    var parent = element.parentNode;
    if (!parent || parent === document.body) return;
    while (parent.firstChild) parent.parentNode.insertBefore(parent.firstChild, parent);
    parent.parentNode.removeChild(parent);
  },

  isVisible: function(element) {
    return element.offsetWidth > 0 || element.offsetHeight > 0;
  },

  // jQuery の toggle() と同じく、隠す時は元の display を覚えておき、見せる時に戻す
  toggle: function(element) {
    if (guidesIndex.isVisible(element)) {
      var display = getComputedStyle(element).display;
      if (display !== "none") element.oldDisplay = display;
      element.style.display = "none";
    } else {
      if (element.style.display === "none" && !element.oldDisplay) element.style.display = "";
      if (element.style.display === "" && getComputedStyle(element).display === "none") element.oldDisplay = "block";
      if (element.style.display === "" || element.style.display === "none") element.style.display = element.oldDisplay || "";
    }
  }
};
