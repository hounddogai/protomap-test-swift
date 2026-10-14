import AcmePlatform
import Foundation

extension Imaging {
    /// A rule a seasonal study digest must pass. Check returns its problems, or none.
    protocol SeasonalStudyDigestRule {
        func check(_ item: SeasonalStudyDigest) -> [String]
    }

    final class SeasonalStudyDigestNotesLengthRule: SeasonalStudyDigestRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: SeasonalStudyDigest) -> [String] {
            let size = item.notes.count
            if size > maxLength {
                return ["notes is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class SeasonalStudyDigestAttemptsRangeRule: SeasonalStudyDigestRule {
        var min: Int
        var max: Int

        init(min: Int, max: Int) {
            self.min = min
            self.max = max
        }

        func check(_ item: SeasonalStudyDigest) -> [String] {
            let value = item.attempts
            var problems: [String] = []
            if value < min {
                problems.append("attempts \(value) is below \(min)")
            }
            if value > max {
                problems.append("attempts \(value) is above \(max)")
            }
            return problems
        }
    }

    final class SeasonalStudyDigestCodePrefixRule: SeasonalStudyDigestRule {
        var prefix: String

        init(prefix: String) {
            self.prefix = prefix
        }

        func check(_ item: SeasonalStudyDigest) -> [String] {
            if !item.code.uppercased().hasPrefix(prefix.uppercased()) {
                return ["code must start with \(prefix)"]
            }
            return []
        }
    }

    final class SeasonalStudyDigestAllowedNotesRule: SeasonalStudyDigestRule {
        var allowed: [String]

        init(allowed: [String]) {
            self.allowed = allowed
        }

        func check(_ item: SeasonalStudyDigest) -> [String] {
            if allowed.count == 0 {
                return []
            }
            if !allowed.contains(Kit.Text.normalize(item.notes)) {
                return ["notes \(item.notes) is inconsistent"]
            }
            return []
        }
    }

    final class SeasonalStudyDigestRequiredNotesRule: SeasonalStudyDigestRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: SeasonalStudyDigest) -> [String] {
            if item.notes.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class SeasonalStudyDigestRequiredCodeRule: SeasonalStudyDigestRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: SeasonalStudyDigest) -> [String] {
            if item.code.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    /// Runs every rule of a seasonal study digest.
    final class SeasonalStudyDigestValidator {
        var rules: [any SeasonalStudyDigestRule]

        init(rules: [any SeasonalStudyDigestRule]) {
            self.rules = rules
        }

        func validate(_ item: SeasonalStudyDigest) -> [String] {
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

        func requireValid(_ item: SeasonalStudyDigest) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.displayLabel()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [SeasonalStudyDigest]) -> [String: [String]] {
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

    static func defaultSeasonalStudyDigestValidator() -> SeasonalStudyDigestValidator {
        return SeasonalStudyDigestValidator(
            rules: [
                SeasonalStudyDigestNotesLengthRule(maxLength: 3600),
                SeasonalStudyDigestAttemptsRangeRule(min: 16, max: 255),
                SeasonalStudyDigestCodePrefixRule(prefix: "Q"),
                SeasonalStudyDigestAllowedNotesRule(allowed: ["adaptive", "rolling"]),
                SeasonalStudyDigestRequiredNotesRule(message: "seasonal study digest needs an entry"),
                SeasonalStudyDigestRequiredCodeRule(message: "seasonal study digest needs this field"),
            ]
        )
    }
}
