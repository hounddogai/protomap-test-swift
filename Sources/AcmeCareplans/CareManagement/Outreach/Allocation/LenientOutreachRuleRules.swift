import AcmePlatform
import Foundation

extension CareManagement {
    /// A rule a lenient outreach rule must pass. Check returns its problems, or none.
    protocol LenientOutreachRuleRule {
        func check(_ item: LenientOutreachRule) -> [String]
    }

    final class LenientOutreachRuleRequiredPhoneRule: LenientOutreachRuleRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: LenientOutreachRule) -> [String] {
            if item.phone.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class LenientOutreachRulePriorityRangeRule: LenientOutreachRuleRule {
        var min: Int
        var max: Int

        init(min: Int, max: Int) {
            self.min = min
            self.max = max
        }

        func check(_ item: LenientOutreachRule) -> [String] {
            let value = item.priority
            var problems: [String] = []
            if value < min {
                problems.append("priority \(value) is below \(min)")
            }
            if value > max {
                problems.append("priority \(value) is above \(max)")
            }
            return problems
        }
    }

    final class LenientOutreachRuleFloorValueRangeRule: LenientOutreachRuleRule {
        var min: Double
        var max: Double

        init(min: Double, max: Double) {
            self.min = min
            self.max = max
        }

        func check(_ item: LenientOutreachRule) -> [String] {
            let value = item.floorValue
            if value < min || value > max {
                return ["floor value \(value) is outside \(min) to \(max)"]
            }
            return []
        }
    }

    final class LenientOutreachRuleRequiredCodeRule: LenientOutreachRuleRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: LenientOutreachRule) -> [String] {
            if item.code.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class LenientOutreachRuleDurationMinutesRangeRule: LenientOutreachRuleRule {
        var min: Int
        var max: Int

        init(min: Int, max: Int) {
            self.min = min
            self.max = max
        }

        func check(_ item: LenientOutreachRule) -> [String] {
            let value = item.durationMinutes
            var problems: [String] = []
            if value < min {
                problems.append("duration minutes \(value) is below \(min)")
            }
            if value > max {
                problems.append("duration minutes \(value) is above \(max)")
            }
            return problems
        }
    }

    /// Runs every rule of a lenient outreach rule.
    final class LenientOutreachRuleValidator {
        var rules: [any LenientOutreachRuleRule]

        init(rules: [any LenientOutreachRuleRule]) {
            self.rules = rules
        }

        func validate(_ item: LenientOutreachRule) -> [String] {
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

        func requireValid(_ item: LenientOutreachRule) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.label()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [LenientOutreachRule]) -> [String: [String]] {
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

    static func defaultLenientOutreachRuleValidator() -> LenientOutreachRuleValidator {
        return LenientOutreachRuleValidator(
            rules: [
                LenientOutreachRuleRequiredPhoneRule(message: "lenient outreach rule needs this field"),
                LenientOutreachRulePriorityRangeRule(min: 255, max: 3600),
                LenientOutreachRuleFloorValueRangeRule(min: 6.9, max: 3696.1),
                LenientOutreachRuleRequiredCodeRule(message: "lenient outreach rule needs this field"),
                LenientOutreachRuleDurationMinutesRangeRule(min: 32, max: 32),
            ]
        )
    }
}
