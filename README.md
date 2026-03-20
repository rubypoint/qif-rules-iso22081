# QIF Rules Extension Prototype for Digital Specifications

This repository contains the prototype schema extension, rule implementation, and example QIF MBD model used for the [ISO 22081:2021](https://www.iso.org/standard/72514.html) case study in the paper "Specifications-as-code: a system for creation of product characteristics from digital specifications."

The repository includes: 

- Bundled QIF 3.0 and QIF 4 work-in-progress schemas used by the prototype.
- The Rubypoint extension to the QIF schemas to support digital specifications.
- An example ISO 22081 implementation as a QIF Rules file.
- An example QIF MBD model modeled after ISO 22081, Figure 3, to demonstrate default geometrical specification rules.

## Repository Contents

All schemas live in `xsd/`:

- `xsd/qif3/` – QIF 3.0 schemas for the QIF MBD model
- `xsd/qif4-wip/` – local work-in-progress version of QIF 4 for the QIF Rules extension
- `xsd/rubypoint.xsd` – custom Rubypoint schema defining the extensions to QIF Rules to support digital specifications

> Note: an in-progress version of QIF 4 is used for the QIF Rules extension to help with future compatibility with this upcoming QIF release.

All QIF instance files live in `qif/`:

- `qif/rules/ISO_22081_2021.qif` – the QIF-Rules-based implementation of ISO 22081, Section 5.
- `qif/mbd/ISO22081_FIG3.qif` – a QIF MBD implementation of the model seen in ISO 22081, Figure 3. The rule above can be executed on this part to automatically apply the applicable geometrical specifications. 

## License

The original schema extension, example rule file, example QIF MBD file, and other repository-authored content are released under the MIT License. Bundled third-party QIF schemas in `xsd/qif3/` and `xsd/qif4-wip/` are not covered by the MIT License and remain subject to their respective copyright and licensing terms.

## About Rubypoint

Have any questions? Get in touch with us here:

[![Website](https://img.shields.io/badge/Website-rubypoint.io-9D0B28?style=for-the-badge)](https://rubypoint.io/) 

[![LinkedIn](https://img.shields.io/badge/LinkedIn-0077B5?style=for-the-badge&logo=linkedin&logoColor=white)](https://www.linkedin.com/company/rubypoint/)