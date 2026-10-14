import AcmePlatform
import Foundation

extension Staffing {
    /// A rule a skill mix segment must pass. Check returns its problems, or none.
    protocol SkillMixSegmentRule {
        func check(_ item: SkillMixSegment) -> [String]
    }

    final class SkillMixSegmentCopayRangeRule: SkillMixSegmentRule {
        var min: Double
        var max: Double

        init(min: Double, max: Double) {
            self.min = min
            self.max = max
        }

        func check(_ item: SkillMixSegment) -> [String] {
            let value = item.copay
            if value < min || value > max {
                return ["copay \(value) is outside \(min) to \(max)"]
            }
            return []
        }
    }

    final class SkillMixSegmentRequiredLabelRule: SkillMixSegmentRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: SkillMixSegment) -> [String] {
            if item.label.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class SkillMixSegmentLabelLengthRule: SkillMixSegmentRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: SkillMixSegment) -> [String] {
            let size = item.label.count
            if size > maxLength {
                return ["label is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class SkillMixSegmentCodeLengthRule: SkillMixSegmentRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: SkillMixSegment) -> [String] {
            let size = item.code.count
            if size > maxLength {
                return ["code is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class SkillMixSegmentRateRangeRule: SkillMixSegmentRule {
        var min: Double
        var max: Double

        init(min: Double, max: Double) {
            self.min = min
            self.max = max
        }

        func check(_ item: SkillMixSegment) -> [String] {
            let value = item.rate
            if value < min || value > max {
                return ["rate \(value) is outside \(min) to \(max)"]
            }
            return []
        }
    }

    final class SkillMixSegmentSegmentLengthRule: SkillMixSegmentRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: SkillMixSegment) -> [String] {
            let size = item.segment.count
            if size > maxLength {
                return ["segment is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    /// Runs every rule of a skill mix segment.
    final class SkillMixSegmentValidator {
        var rules: [any SkillMixSegmentRule]

        init(rules: [any SkillMixSegmentRule]) {
            self.rules = rules
        }

        func validate(_ item: SkillMixSegment) -> [String] {
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

        func requireValid(_ item: SkillMixSegment) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.displayLabel()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [SkillMixSegment]) -> [String: [String]] {
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

    static func defaultSkillMixSegmentValidator() -> SkillMixSegmentValidator {
        return SkillMixSegmentValidator(
            rules: [
                SkillMixSegmentCopayRangeRule(min: 5.3, max: 4228.6),
                SkillMixSegmentRequiredLabelRule(message: "skill mix segment needs a value"),
                SkillMixSegmentLabelLengthRule(maxLength: 3600),
                SkillMixSegmentCodeLengthRule(maxLength: 1000),
                SkillMixSegmentRateRangeRule(min: 2.4, max: 357.9),
                SkillMixSegmentSegmentLengthRule(maxLength: 3600),
            ]
        )
    }
}
