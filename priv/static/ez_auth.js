// EzAuth LiveView hooks, exported for host apps to merge into their LiveSocket.
//
//   import * as EzAuthHooks from "ez_auth"
//   new LiveSocket("/live", Socket, { hooks: { ...EzAuthHooks, ...appHooks } })
//

const PATTERNS = {
  numeric: /[^0-9]/g,
  alphanumeric: /[^0-9a-zA-Z]/g,
};

export const CodeInput = {
  mounted() {
    const inputs = this.el.querySelectorAll("input");
    const pattern = PATTERNS[this.el.dataset.format] || PATTERNS.numeric;

    inputs.forEach((input, index) => {
      input.addEventListener("focus", (e) => e.target.select());

      input.addEventListener("keydown", (e) => {
        if (e.key === "ArrowLeft" && index > 0) {
          e.preventDefault();
          inputs[index - 1].focus();
        }

        if (e.key === "ArrowRight" && index < inputs.length - 1) {
          e.preventDefault();
          inputs[index + 1].focus();
        }

        if (e.key === "Backspace" && !input.value && index > 0) {
          inputs[index - 1].focus();
          inputs[index - 1].value = "";
        }
      });

      input.addEventListener("input", (e) => {
        const value = e.target.value;
        if (value.length > 0) {
          const filtered = value[value.length - 1].replace(pattern, "");
          input.value = filtered;
          if (filtered && index < inputs.length - 1) {
            inputs[index + 1].focus();
          }
        }
      });

      input.addEventListener("paste", (e) => {
        e.preventDefault();
        const pasted = e.clipboardData.getData("text").replace(pattern, "").split("");
        inputs.forEach((input, i) => {
          if (pasted[i]) input.value = pasted[i];
        });
        inputs[inputs.length - 1].focus();
      });
    });
  },
};

export default { CodeInput };
