import AcmePlatform
import Foundation

extension Staffing {
    /// A rule a overtime variance must pass. Check returns its problems, or none.
    protocol OvertimeVarianceRule {
        func check(_ item: OvertimeVariance) -> [String]
    }

    final class OvertimeVarianceRequiredCodeRule: OvertimeVarianceRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: OvertimeVariance) -> [String] {
            if item.code.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class OvertimeVarianceVersionRangeRule: OvertimeVarianceRule {
        var min: Int
        var max: Int

        init(min: Int, max: Int) {
            self.min = min
            self.max = max
        }

        func check(_ item: OvertimeVariance) -> [String] {
            let value = item.version
            if value < min || value > max {
                return ["version \(value) is outside \(min) to \(max)"]
            }
            return []
        }
    }

    final class OvertimeVarianceRequiredOwnerIDRule: OvertimeVarianceRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: OvertimeVariance) -> [String] {
            if item.ownerID.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    /// Runs every rule of a overtime variance.
    final class OvertimeVarianceValidator {
        var rules: [any OvertimeVarianceRule]

        init(rules: [any OvertimeVarianceRule]) {
            self.rules = rules
        }

        func validate(_ item: OvertimeVariance) -> [String] {
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

        func requireValid(_ item: OvertimeVariance) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.label()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [OvertimeVariance]) -> [String: [String]] {
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

    static func defaultOvertimeVarianceValidator() -> OvertimeVarianceValidator {
        return OvertimeVarianceValidator(
            rules: [
                OvertimeVarianceRequiredCodeRule(message: "overtime variance needs this field"),
                OvertimeVarianceVersionRangeRule(min: 16, max: 80),
                OvertimeVarianceRequiredOwnerIDRule(message: "overtime variance needs an entry"),
            ]
        )
    }
}
