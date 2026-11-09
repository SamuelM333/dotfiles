// Firefox prefs, copied into every profile by
// .chezmoiscripts/run_after_firefox-user-js.sh.tmpl. Firefox applies them on
// each start, so changes made in about:config are reset on the next launch.
// Removing a line here doesn't reset its pref: change it back in about:config.

// Hold the first paint until the CSS has usually arrived, so pages don't
// flash unstyled while loading. Defaults are 5 ms.
user_pref("nglayout.initialpaint.delay", 350);
user_pref("nglayout.initialpaint.delay_in_oopif", 350);
// Redraw a loading page every 0.5 s instead of every 0.12 s.
user_pref("content.notify.interval", 500000);
