import AcmePlatform
import Foundation

extension Referrals {
    /// A rule a pending slot target must pass. Check returns its problems, or none.
    protocol PendingSlotTargetRule {
        func check(_ item: PendingSlotTarget) -> [String]
    }

    final class PendingSlotTargetRequiredNameRule: PendingSlotTargetRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: PendingSlotTarget) -> [String] {
            if item.name.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class PendingSlotTargetAmountRangeRule: PendingSlotTargetRule {
        var min: Double
        var max: Double

        init(min: Double, max: Double) {
            self.min = min
            self.max = max
        }

        func check(_ item: PendingSlotTarget) -> [String] {
            let value = item.amount
            if value < min || value > max {
                return ["amount \(value) is outside \(min) to \(max)"]
            }
            return []
        }
    }

    final class PendingSlotTargetRequiredCodeRule: PendingSlotTargetRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: PendingSlotTarget) -> [String] {
            if item.code.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class PendingSlotTargetRequiredProcedureCodeRule: PendingSlotTargetRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: PendingSlotTarget) -> [String] {
            if item.procedureCode.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    /// Runs every rule of a pending slot target.
    final class PendingSlotTargetValidator {
        var rules: [any PendingSlotTargetRule]

        init(rules: [any PendingSlotTargetRule]) {
            self.rules = rules
        }

        func validate(_ item: PendingSlotTarget) -> [String] {
            var problems: [String] = []
            for rule in rules {
                for problem in rule.check(item) {
                    problems.append(problem)
                }
            }
            return problems
        }

        func requireValid(_ item: PendingSlotTarget) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.label()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [PendingSlotTarget]) -> [String: [String]] {
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

    static func defaultPendingSlotTargetValidator() -> PendingSlotTargetValidator {
        return PendingSlotTargetValidator(
            rules: [
                PendingSlotTargetRequiredNameRule(message: "pending slot target needs a value"),
                PendingSlotTargetAmountRangeRule(min: 8.5, max: 4300.0),
                PendingSlotTargetRequiredCodeRule(message: "pending slot target needs a value"),
                PendingSlotTargetRequiredProcedureCodeRule(message: "pending slot target needs an entry"),
            ]
        )
    }
}
