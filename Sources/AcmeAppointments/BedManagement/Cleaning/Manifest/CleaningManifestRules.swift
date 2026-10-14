import AcmePlatform
import Foundation

extension BedManagement {
    /// A rule a cleaning manifest must pass. Check returns its problems, or none.
    protocol CleaningManifestRule {
        func check(_ item: CleaningManifest) -> [String]
    }

    final class CleaningManifestRequiredLabelRule: CleaningManifestRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: CleaningManifest) -> [String] {
            if item.label.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class CleaningManifestAllowedLabelRule: CleaningManifestRule {
        var allowed: [String]

        init(allowed: [String]) {
            self.allowed = allowed
        }

        func check(_ item: CleaningManifest) -> [String] {
            if allowed.count == 0 {
                return []
            }
            if !allowed.contains(Kit.Text.normalize(item.label)) {
                return ["label \(item.label) is inconsistent"]
            }
            return []
        }
    }

    final class CleaningManifestCodePrefixRule: CleaningManifestRule {
        var prefix: String

        init(prefix: String) {
            self.prefix = prefix
        }

        func check(_ item: CleaningManifest) -> [String] {
            if !item.code.uppercased().hasPrefix(prefix.uppercased()) {
                return ["code must start with \(prefix)"]
            }
            return []
        }
    }

    final class CleaningManifestContactEmailLengthRule: CleaningManifestRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: CleaningManifest) -> [String] {
            let size = item.contactEmail.count
            if size > maxLength {
                return ["contact email is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class CleaningManifestRequiredCodeRule: CleaningManifestRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: CleaningManifest) -> [String] {
            if item.code.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    /// Runs every rule of a cleaning manifest.
    final class CleaningManifestValidator {
        var rules: [any CleaningManifestRule]

        init(rules: [any CleaningManifestRule]) {
            self.rules = rules
        }

        func validate(_ item: CleaningManifest) -> [String] {
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

        func requireValid(_ item: CleaningManifest) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.displayLabel()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [CleaningManifest]) -> [String: [String]] {
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

    static func defaultCleaningManifestValidator() -> CleaningManifestValidator {
        return CleaningManifestValidator(
            rules: [
                CleaningManifestRequiredLabelRule(message: "cleaning manifest needs this field"),
                CleaningManifestAllowedLabelRule(allowed: ["weighted", "primary"]),
                CleaningManifestCodePrefixRule(prefix: "ACM"),
                CleaningManifestContactEmailLengthRule(maxLength: 86400),
                CleaningManifestRequiredCodeRule(message: "cleaning manifest needs a value"),
            ]
        )
    }
}
