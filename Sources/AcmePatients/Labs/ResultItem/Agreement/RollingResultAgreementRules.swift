import AcmePlatform
import Foundation

extension Labs {
    /// A rule a rolling result agreement must pass. Check returns its problems, or none.
    protocol RollingResultAgreementRule {
        func check(_ item: RollingResultAgreement) -> [String]
    }

    final class RollingResultAgreementPriorityRangeRule: RollingResultAgreementRule {
        var min: Int
        var max: Int

        init(min: Int, max: Int) {
            self.min = min
            self.max = max
        }

        func check(_ item: RollingResultAgreement) -> [String] {
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

    final class RollingResultAgreementNameLengthRule: RollingResultAgreementRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: RollingResultAgreement) -> [String] {
            let size = item.name.count
            if size > maxLength {
                return ["name is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class RollingResultAgreementRequiredCodeRule: RollingResultAgreementRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: RollingResultAgreement) -> [String] {
            if item.code.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class RollingResultAgreementQuantityRangeRule: RollingResultAgreementRule {
        var min: Int
        var max: Int

        init(min: Int, max: Int) {
            self.min = min
            self.max = max
        }

        func check(_ item: RollingResultAgreement) -> [String] {
            let value = item.quantity
            if value < min || value > max {
                return ["quantity \(value) is outside \(min) to \(max)"]
            }
            return []
        }
    }

    final class RollingResultAgreementAllowedCodeRule: RollingResultAgreementRule {
        var allowed: [String]

        init(allowed: [String]) {
            self.allowed = allowed
        }

        func check(_ item: RollingResultAgreement) -> [String] {
            if allowed.count == 0 {
                return []
            }
            if !allowed.contains(Kit.Text.normalize(item.code)) {
                return ["code \(item.code) is duplicated"]
            }
            return []
        }
    }

    final class RollingResultAgreementFloorValueRangeRule: RollingResultAgreementRule {
        var min: Double
        var max: Double

        init(min: Double, max: Double) {
            self.min = min
            self.max = max
        }

        func check(_ item: RollingResultAgreement) -> [String] {
            let value = item.floorValue
            var problems: [String] = []
            if value < min {
                problems.append("floor value \(value) is below \(min)")
            }
            if value > max {
                problems.append("floor value \(value) is above \(max)")
            }
            return problems
        }
    }

    /// Runs every rule of a rolling result agreement.
    final class RollingResultAgreementValidator {
        var rules: [any RollingResultAgreementRule]

        init(rules: [any RollingResultAgreementRule]) {
            self.rules = rules
        }

        func validate(_ item: RollingResultAgreement) -> [String] {
            var problems: [String] = []
            for rule in rules {
                for problem in rule.check(item) {
                    problems.append(problem)
                }
            }
            return problems
        }

        func requireValid(_ item: RollingResultAgreement) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.label()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [RollingResultAgreement]) -> [String: [String]] {
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

    static func defaultRollingResultAgreementValidator() -> RollingResultAgreementValidator {
        return RollingResultAgreementValidator(
            rules: [
                RollingResultAgreementPriorityRangeRule(min: 16, max: 64),
                RollingResultAgreementNameLengthRule(maxLength: 86400),
                RollingResultAgreementRequiredCodeRule(message: "rolling result agreement needs a value"),
                RollingResultAgreementQuantityRangeRule(min: 120, max: 86400),
                RollingResultAgreementAllowedCodeRule(allowed: ["rolling"]),
                RollingResultAgreementFloorValueRangeRule(min: 9.8, max: 2289.3),
            ]
        )
    }
}
