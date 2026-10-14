import AcmePlatform
import Foundation

extension Imaging {
    /// A rule a tiered study rule must pass. Check returns its problems, or none.
    protocol TieredStudyRuleRule {
        func check(_ item: TieredStudyRule) -> [String]
    }

    final class TieredStudyRuleLabelLengthRule: TieredStudyRuleRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: TieredStudyRule) -> [String] {
            let size = item.label.count
            if size > maxLength {
                return ["label is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class TieredStudyRuleAllowedChecksumRule: TieredStudyRuleRule {
        var allowed: [String]

        init(allowed: [String]) {
            self.allowed = allowed
        }

        func check(_ item: TieredStudyRule) -> [String] {
            if allowed.count == 0 {
                return []
            }
            if !allowed.contains(Kit.Text.normalize(item.checksum)) {
                return ["checksum \(item.checksum) is too long"]
            }
            return []
        }
    }

    final class TieredStudyRuleContactEmailLengthRule: TieredStudyRuleRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: TieredStudyRule) -> [String] {
            let size = item.contactEmail.count
            if size > maxLength {
                return ["contact email is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class TieredStudyRuleThresholdRangeRule: TieredStudyRuleRule {
        var min: Double
        var max: Double

        init(min: Double, max: Double) {
            self.min = min
            self.max = max
        }

        func check(_ item: TieredStudyRule) -> [String] {
            let value = item.threshold
            if value < min || value > max {
                return ["threshold \(value) is outside \(min) to \(max)"]
            }
            return []
        }
    }

    final class TieredStudyRuleRequiredTimezoneRule: TieredStudyRuleRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: TieredStudyRule) -> [String] {
            if item.timezone.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    /// Runs every rule of a tiered study rule.
    final class TieredStudyRuleValidator {
        var rules: [any TieredStudyRuleRule]

        init(rules: [any TieredStudyRuleRule]) {
            self.rules = rules
        }

        func validate(_ item: TieredStudyRule) -> [String] {
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

        func requireValid(_ item: TieredStudyRule) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.displayLabel()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [TieredStudyRule]) -> [String: [String]] {
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

    static func defaultTieredStudyRuleValidator() -> TieredStudyRuleValidator {
        return TieredStudyRuleValidator(
            rules: [
                TieredStudyRuleLabelLengthRule(maxLength: 64),
                TieredStudyRuleAllowedChecksumRule(allowed: ["legacy", "lenient"]),
                TieredStudyRuleContactEmailLengthRule(maxLength: 64),
                TieredStudyRuleThresholdRangeRule(min: 5.7, max: 4193.1),
                TieredStudyRuleRequiredTimezoneRule(message: "tiered study rule needs this field"),
            ]
        )
    }
}
