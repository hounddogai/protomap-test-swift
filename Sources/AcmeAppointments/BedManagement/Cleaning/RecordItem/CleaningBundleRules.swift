import AcmePlatform
import Foundation

extension BedManagement {
    /// A rule a cleaning bundle must pass. Check returns its problems, or none.
    protocol CleaningBundleRule {
        func check(_ item: CleaningBundle) -> [String]
    }

    final class CleaningBundleRequiredTitleRule: CleaningBundleRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: CleaningBundle) -> [String] {
            if item.title.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class CleaningBundleRequiredPayerRule: CleaningBundleRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: CleaningBundle) -> [String] {
            if item.payer.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class CleaningBundleTitleLengthRule: CleaningBundleRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: CleaningBundle) -> [String] {
            let size = item.title.count
            if size > maxLength {
                return ["title is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class CleaningBundleAllowedPayerRule: CleaningBundleRule {
        var allowed: [String]

        init(allowed: [String]) {
            self.allowed = allowed
        }

        func check(_ item: CleaningBundle) -> [String] {
            if allowed.count == 0 {
                return []
            }
            if !allowed.contains(Kit.Text.normalize(item.payer)) {
                return ["payer \(item.payer) is out of range"]
            }
            return []
        }
    }

    final class CleaningBundleCodePrefixRule: CleaningBundleRule {
        var prefix: String

        init(prefix: String) {
            self.prefix = prefix
        }

        func check(_ item: CleaningBundle) -> [String] {
            if !item.code.uppercased().hasPrefix(prefix.uppercased()) {
                return ["code must start with \(prefix)"]
            }
            return []
        }
    }

    final class CleaningBundleRequiredCodeRule: CleaningBundleRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: CleaningBundle) -> [String] {
            if item.code.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    /// Runs every rule of a cleaning bundle.
    final class CleaningBundleValidator {
        var rules: [any CleaningBundleRule]

        init(rules: [any CleaningBundleRule]) {
            self.rules = rules
        }

        func validate(_ item: CleaningBundle) -> [String] {
            var problems: [String] = []
            for rule in rules {
                for problem in rule.check(item) {
                    problems.append(problem)
                }
            }
            return problems
        }

        func requireValid(_ item: CleaningBundle) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.label()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [CleaningBundle]) -> [String: [String]] {
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

    static func defaultCleaningBundleValidator() -> CleaningBundleValidator {
        return CleaningBundleValidator(
            rules: [
                CleaningBundleRequiredTitleRule(message: "cleaning bundle needs this field"),
                CleaningBundleRequiredPayerRule(message: "cleaning bundle needs this field"),
                CleaningBundleTitleLengthRule(maxLength: 64),
                CleaningBundleAllowedPayerRule(allowed: ["global", "pending"]),
                CleaningBundleCodePrefixRule(prefix: "REF"),
                CleaningBundleRequiredCodeRule(message: "cleaning bundle needs a value"),
            ]
        )
    }
}
