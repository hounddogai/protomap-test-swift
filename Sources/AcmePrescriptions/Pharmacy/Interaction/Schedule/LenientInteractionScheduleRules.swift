import AcmePlatform
import Foundation

extension Pharmacy {
    /// A rule a lenient interaction schedule must pass. Check returns its problems, or none.
    protocol LenientInteractionScheduleRule {
        func check(_ item: LenientInteractionSchedule) -> [String]
    }

    final class LenientInteractionScheduleRequiredCodeRule: LenientInteractionScheduleRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: LenientInteractionSchedule) -> [String] {
            if item.code.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class LenientInteractionScheduleAllowedCodeRule: LenientInteractionScheduleRule {
        var allowed: [String]

        init(allowed: [String]) {
            self.allowed = allowed
        }

        func check(_ item: LenientInteractionSchedule) -> [String] {
            if allowed.count == 0 {
                return []
            }
            if !allowed.contains(Kit.Text.normalize(item.code)) {
                return ["code \(item.code) is below minimum"]
            }
            return []
        }
    }

    final class LenientInteractionScheduleVisitMinutesRangeRule: LenientInteractionScheduleRule {
        var min: Int
        var max: Int

        init(min: Int, max: Int) {
            self.min = min
            self.max = max
        }

        func check(_ item: LenientInteractionSchedule) -> [String] {
            let value = item.visitMinutes
            var problems: [String] = []
            if value < min {
                problems.append("visit minutes \(value) is below \(min)")
            }
            if value > max {
                problems.append("visit minutes \(value) is above \(max)")
            }
            return problems
        }
    }

    final class LenientInteractionScheduleRequiredOwnerIDRule: LenientInteractionScheduleRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: LenientInteractionSchedule) -> [String] {
            if item.ownerID.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class LenientInteractionScheduleCopayRangeRule: LenientInteractionScheduleRule {
        var min: Double
        var max: Double

        init(min: Double, max: Double) {
            self.min = min
            self.max = max
        }

        func check(_ item: LenientInteractionSchedule) -> [String] {
            let value = item.copay
            var problems: [String] = []
            if value < min {
                problems.append("copay \(value) is below \(min)")
            }
            if value > max {
                problems.append("copay \(value) is above \(max)")
            }
            return problems
        }
    }

    /// Runs every rule of a lenient interaction schedule.
    final class LenientInteractionScheduleValidator {
        var rules: [any LenientInteractionScheduleRule]

        init(rules: [any LenientInteractionScheduleRule]) {
            self.rules = rules
        }

        func validate(_ item: LenientInteractionSchedule) -> [String] {
            var problems: [String] = []
            for rule in rules {
                for problem in rule.check(item) {
                    problems.append(problem)
                }
            }
            return problems
        }

        func requireValid(_ item: LenientInteractionSchedule) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.label()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [LenientInteractionSchedule]) -> [String: [String]] {
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

    static func defaultLenientInteractionScheduleValidator() -> LenientInteractionScheduleValidator {
        return LenientInteractionScheduleValidator(
            rules: [
                LenientInteractionScheduleRequiredCodeRule(message: "lenient interaction schedule needs a value"),
                LenientInteractionScheduleAllowedCodeRule(allowed: ["lenient", "capped", "primary"]),
                LenientInteractionScheduleVisitMinutesRangeRule(min: 16, max: 32),
                LenientInteractionScheduleRequiredOwnerIDRule(
                    message: "lenient interaction schedule needs this field"
                ),
                LenientInteractionScheduleCopayRangeRule(min: 0.2, max: 1237.0),
            ]
        )
    }
}
