---
name: audit
description: Security auditing guidance. Use when designing, reviewing, or implementing any auth feature.
---

# Audit Skill

Audit auth features against OWASP ASVS, OWASP Cheat Sheets, and NIST SP 800-63B-4.

**IMPORTANT**: When auditing, take into consideration that this project is a library, not a full application, so responsability is limited to the constraints of the exposed APIs. Before filing a finding, ask: "Would remediating this require the library to make a policy choice the host is better positioned to make?". If yes, it's likely out of scope (as a host-app responsibility). The library's contract is providing safe primitives with clear extension points, not complete feature parity that supports every possible workflow.

## Core Principles

- Never expose APIs that allow insecure usage.
- Critical flows must not rely on developer discipline.
- Prefer safe defaults over configurability when possible.
- Don't invent auth rules; always anchor findings to a recognized standard.
- Focus on practical security findings over unrealistic UX expectations.

## Scope

Scope is the set of files listed by `git diff --name-only <base>...HEAD` against the repo's base branch, or the whole codebase when that set is empty. Read each in-scope file in full before raising findings.

## Sources

### Primary Sources (always applicable)

- **OWASP ASVS**
  - Use for: authentication (V2), sessions (V3), access control (V4), cryptography (V6).
  - Reference: https://owasp.org/www-project-application-security-verification-standard/
- **OWASP Cheat Sheet Series**
  - Use for: Authentication, Password Storage, Session Management, MFA, Authorization.
  - Reference: https://cheatsheetseries.owasp.org/
- **NIST SP 800-63B-4**
  - Use for: authenticator strength, MFA, reauthentication, recovery flows.
  - Reference: https://csrc.nist.gov/pubs/sp/800/63/b/4/final

### Secondary Sources (use only if relevant)

- **RFC 9700** (OAuth 2.0 Security BCP)
  - Use for: OAuth / OIDC flows.
  - Reference: https://datatracker.ietf.org/doc/rfc9700/
- **RFC 8725** (JWT Best Current Practices)
  - Use for: JWT handling.
  - Reference: https://datatracker.ietf.org/doc/html/rfc8725
- **WebAuthn Level 3**
  - Use for: passkeys and WebAuthn implementations.
  - Reference: https://www.w3.org/TR/webauthn-3/
- **OWASP MASVS**
  - Use for: mobile SDK auth flows.
  - Reference: https://mas.owasp.org/MASVS/

## Process

1. Read the code before citing a standard; audits reflect real behavior, not assumed behavior.
2. Compare actual behavior against the relevant standard section. When sources conflict, prefer the stricter interpretation and the newer standard.
3. Default to the most secure reasonable option; don't make security optional without justification.
4. Cite the source that drove each decision (e.g., "ASVS V3.4.4", "NIST 800-63B-4 §5.2.2").
5. If no source applies, say so and choose the conservative default.

## Judgment/ Calibration

A paper violation isn't always a real risk. Before raising a finding, check:

- Does the surrounding architecture already neutralize it?
  (Cookie flags enforced by the host endpoint, TLS at the edge, etc.)
- Is it a library concern or a host-app concern?
  Document host-side requirements; don't flag them as library defects.
- Does the threat model actually apply?
  (Timing attacks against 256-bit random tokens aren't tractable.)
- Is the issue already mitigated elsewhere in the flow?
  Make sure to trace the full path first.

## Output

Write an `audit-{date}.md` at the repo root using the **OWASP Web Security Testing Guide** finding template. 
Score severity with **CVSS v4.0** (None / Low / Medium / High / Critical); classify weaknesses with **CWE** IDs.

Each finding should have:

- **Title**
- **Severity**: CVSS v4.0 qualitative (+ vector string if useful)
- **CWE:** CWE name + link to the website.
- **Description**: what the code does and why/how it creates the issue.
- **Impact**: step by step, concrete threat scenario narrative (easy to read).
- **Remediation**: describe one specific fix in general terminology (no details).
- **References**: ASVS / cheat-sheet / NIST / RFC sections.
- **Proposal**: Specific proposal code diff with explanations.

Number findings sequentially, highest severity first. Open with a one-paragraph summary (scope + counts by severity).
