import AcmePlatform
import Foundation

extension BedManagement {
    /// A rule a cleaning digest must pass. Check returns its problems, or none.
    protocol CleaningDigestRule {
        func check(_ item: CleaningDigest) -> [String]
    }

    final class CleaningDigestCodePrefixRule: CleaningDigestRule {
        var prefix: String

        init(prefix: String) {
            self.prefix = prefix
        }

        func check(_ item: CleaningDigest) -> [String] {
            if !item.code.uppercased().hasPrefix(prefix.uppercased()) {
                return ["code must start with \(prefix)"]
            }
            return []
        }
    }

    final class CleaningDigestVersionRangeRule: CleaningDigestRule {
        var min: Int
        var max: Int

        init(min: Int, max: Int) {
            self.min = min
            self.max = max
        }

        func check(_ item: CleaningDigest) -> [String] {
            let value = item.version
            var problems: [String] = []
            if value < min {
                problems.append("version \(value) is below \(min)")
            }
            if value > max {
                problems.append("version \(value) is above \(max)")
            }
            return problems
        }
    }

    final class CleaningDigestTimezoneLengthRule: CleaningDigestRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: CleaningDigest) -> [String] {
            let size = item.timezone.count
            if size > maxLength {
                return ["timezone is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class CleaningDigestTitleLengthRule: CleaningDigestRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: CleaningDigest) -> [String] {
            let size = item.title.count
            if size > maxLength {
                return ["title is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class CleaningDigestRequiredCodeRule: CleaningDigestRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: CleaningDigest) -> [String] {
            if item.code.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    /// Runs every rule of a cleaning digest.
    final class CleaningDigestValidator {
        var rules: [any CleaningDigestRule]

        init(rules: [any CleaningDigestRule]) {
            self.rules = rules
        }

        func validate(_ item: CleaningDigest) -> [String] {
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

        func requireValid(_ item: CleaningDigest) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.label()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [CleaningDigest]) -> [String: [String]] {
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

    static func defaultCleaningDigestValidator() -> CleaningDigestValidator {
        return CleaningDigestValidator(
            rules: [
                CleaningDigestCodePrefixRule(prefix: "ACM"),
                CleaningDigestVersionRangeRule(min: 32, max: 64),
                CleaningDigestTimezoneLengthRule(maxLength: 86400),
                CleaningDigestTitleLengthRule(maxLength: 1000),
                CleaningDigestRequiredCodeRule(message: "cleaning digest needs a value"),
            ]
        )
    }
}
