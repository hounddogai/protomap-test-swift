import AcmePlatform
import Foundation

extension Staffing {
    /// A rule a regional skill mix segment must pass. Check returns its problems, or none.
    protocol RegionalSkillMixSegmentRule {
        func check(_ item: RegionalSkillMixSegment) -> [String]
    }

    final class RegionalSkillMixSegmentAmountRangeRule: RegionalSkillMixSegmentRule {
        var min: Double
        var max: Double

        init(min: Double, max: Double) {
            self.min = min
            self.max = max
        }

        func check(_ item: RegionalSkillMixSegment) -> [String] {
            let value = item.amount
            if value < min || value > max {
                return ["amount \(value) is outside \(min) to \(max)"]
            }
            return []
        }
    }

    final class RegionalSkillMixSegmentRequiredChecksumRule: RegionalSkillMixSegmentRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: RegionalSkillMixSegment) -> [String] {
            if item.checksum.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class RegionalSkillMixSegmentCurrencyLengthRule: RegionalSkillMixSegmentRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: RegionalSkillMixSegment) -> [String] {
            let size = item.currency.count
            if size > maxLength {
                return ["currency is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    /// Runs every rule of a regional skill mix segment.
    final class RegionalSkillMixSegmentValidator {
        var rules: [any RegionalSkillMixSegmentRule]

        init(rules: [any RegionalSkillMixSegmentRule]) {
            self.rules = rules
        }

        func validate(_ item: RegionalSkillMixSegment) -> [String] {
            var problems: [String] = []
            for rule in rules {
                for problem in rule.check(item) {
                    problems.append(problem)
                }
            }
            return problems
        }

        func requireValid(_ item: RegionalSkillMixSegment) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.label()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [RegionalSkillMixSegment]) -> [String: [String]] {
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

    static func defaultRegionalSkillMixSegmentValidator() -> RegionalSkillMixSegmentValidator {
        return RegionalSkillMixSegmentValidator(
            rules: [
                RegionalSkillMixSegmentAmountRangeRule(min: 0.3, max: 3402.7),
                RegionalSkillMixSegmentRequiredChecksumRule(message: "regional skill mix segment needs a value"),
                RegionalSkillMixSegmentCurrencyLengthRule(maxLength: 3600),
            ]
        )
    }
}
