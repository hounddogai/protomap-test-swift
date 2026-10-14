import AcmePlatform
import Foundation

extension ClinicalOps {
    /// A rule a rolling care protocol profile must pass. Check returns its problems, or none.
    protocol RollingCareProtocolProfileRule {
        func check(_ item: RollingCareProtocolProfile) -> [String]
    }

    final class RollingCareProtocolProfileRequiredTimezoneRule: RollingCareProtocolProfileRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: RollingCareProtocolProfile) -> [String] {
            if item.timezone.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class RollingCareProtocolProfileRequiredWardRule: RollingCareProtocolProfileRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: RollingCareProtocolProfile) -> [String] {
            if item.ward.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class RollingCareProtocolProfileCapacityRangeRule: RollingCareProtocolProfileRule {
        var min: Int
        var max: Int

        init(min: Int, max: Int) {
            self.min = min
            self.max = max
        }

        func check(_ item: RollingCareProtocolProfile) -> [String] {
            let value = item.capacity
            if value < min || value > max {
                return ["capacity \(value) is outside \(min) to \(max)"]
            }
            return []
        }
    }

    final class RollingCareProtocolProfileRevisionRangeRule: RollingCareProtocolProfileRule {
        var min: Int
        var max: Int

        init(min: Int, max: Int) {
            self.min = min
            self.max = max
        }

        func check(_ item: RollingCareProtocolProfile) -> [String] {
            let value = item.revision
            if value < min || value > max {
                return ["revision \(value) is outside \(min) to \(max)"]
            }
            return []
        }
    }

    final class RollingCareProtocolProfileWeightRangeRule: RollingCareProtocolProfileRule {
        var min: Double
        var max: Double

        init(min: Double, max: Double) {
            self.min = min
            self.max = max
        }

        func check(_ item: RollingCareProtocolProfile) -> [String] {
            let value = item.weight
            var problems: [String] = []
            if value < min {
                problems.append("weight \(value) is below \(min)")
            }
            if value > max {
                problems.append("weight \(value) is above \(max)")
            }
            return problems
        }
    }

    final class RollingCareProtocolProfileRequiredTitleRule: RollingCareProtocolProfileRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: RollingCareProtocolProfile) -> [String] {
            if item.title.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    /// Runs every rule of a rolling care protocol profile.
    final class RollingCareProtocolProfileValidator {
        var rules: [any RollingCareProtocolProfileRule]

        init(rules: [any RollingCareProtocolProfileRule]) {
            self.rules = rules
        }

        func validate(_ item: RollingCareProtocolProfile) -> [String] {
            var problems: [String] = []
            for rule in rules {
                for problem in rule.check(item) {
                    problems.append(problem)
                }
            }
            return problems
        }

        func requireValid(_ item: RollingCareProtocolProfile) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.label()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [RollingCareProtocolProfile]) -> [String: [String]] {
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

    static func defaultRollingCareProtocolProfileValidator() -> RollingCareProtocolProfileValidator {
        return RollingCareProtocolProfileValidator(
            rules: [
                RollingCareProtocolProfileRequiredTimezoneRule(
                    message: "rolling care protocol profile needs this field"
                ),
                RollingCareProtocolProfileRequiredWardRule(message: "rolling care protocol profile needs a value"),
                RollingCareProtocolProfileCapacityRangeRule(min: 120, max: 255),
                RollingCareProtocolProfileRevisionRangeRule(min: 80, max: 3600),
                RollingCareProtocolProfileWeightRangeRule(min: 6.3, max: 961.4),
                RollingCareProtocolProfileRequiredTitleRule(message: "rolling care protocol profile needs an entry"),
            ]
        )
    }
}
