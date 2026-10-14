import AcmePlatform
import Foundation

extension Labs {
    /// A rule a regional panel digest must pass. Check returns its problems, or none.
    protocol RegionalPanelDigestRule {
        func check(_ item: RegionalPanelDigest) -> [String]
    }

    final class RegionalPanelDigestRequiredCodeRule: RegionalPanelDigestRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: RegionalPanelDigest) -> [String] {
            if item.code.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class RegionalPanelDigestCodePrefixRule: RegionalPanelDigestRule {
        var prefix: String

        init(prefix: String) {
            self.prefix = prefix
        }

        func check(_ item: RegionalPanelDigest) -> [String] {
            if !item.code.uppercased().hasPrefix(prefix.uppercased()) {
                return ["code must start with \(prefix)"]
            }
            return []
        }
    }

    final class RegionalPanelDigestClinicianIDLengthRule: RegionalPanelDigestRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: RegionalPanelDigest) -> [String] {
            let size = item.clinicianID.count
            if size > maxLength {
                return ["clinician id is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class RegionalPanelDigestChecksumLengthRule: RegionalPanelDigestRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: RegionalPanelDigest) -> [String] {
            let size = item.checksum.count
            if size > maxLength {
                return ["checksum is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class RegionalPanelDigestRequiredClinicianIDRule: RegionalPanelDigestRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: RegionalPanelDigest) -> [String] {
            if item.clinicianID.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class RegionalPanelDigestRequiredChecksumRule: RegionalPanelDigestRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: RegionalPanelDigest) -> [String] {
            if item.checksum.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    /// Runs every rule of a regional panel digest.
    final class RegionalPanelDigestValidator {
        var rules: [any RegionalPanelDigestRule]

        init(rules: [any RegionalPanelDigestRule]) {
            self.rules = rules
        }

        func validate(_ item: RegionalPanelDigest) -> [String] {
            var problems: [String] = []
            for rule in rules {
                let found = rule.check(item)
                if found.count == 0 {
                    continue
                }
                for problem in found {
                    problems.append("\(item.code): \(problem)")
                }
            }
            return problems
        }

        func requireValid(_ item: RegionalPanelDigest) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.label()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [RegionalPanelDigest]) -> [String: [String]] {
            var report: [String: [String]] = [:]
            for item in items {
                let problems = self.validate(item)
                if problems.count > 0 {
                    report[item.code] = problems
                }
            }
            return report
        }
    }

    static func defaultRegionalPanelDigestValidator() -> RegionalPanelDigestValidator {
        return RegionalPanelDigestValidator(
            rules: [
                RegionalPanelDigestRequiredCodeRule(message: "regional panel digest needs this field"),
                RegionalPanelDigestCodePrefixRule(prefix: "Q"),
                RegionalPanelDigestClinicianIDLengthRule(maxLength: 80),
                RegionalPanelDigestChecksumLengthRule(maxLength: 120),
                RegionalPanelDigestRequiredClinicianIDRule(message: "regional panel digest needs a value"),
                RegionalPanelDigestRequiredChecksumRule(message: "regional panel digest needs an entry"),
            ]
        )
    }
}
