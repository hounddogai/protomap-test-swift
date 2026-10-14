import AcmePlatform
import Foundation

extension ClinicalOps {
    /// A rule a rolling task ledger must pass. Check returns its problems, or none.
    protocol RollingTaskLedgerRule {
        func check(_ item: RollingTaskLedger) -> [String]
    }

    final class RollingTaskLedgerMinimumRangeRule: RollingTaskLedgerRule {
        var min: Double
        var max: Double

        init(min: Double, max: Double) {
            self.min = min
            self.max = max
        }

        func check(_ item: RollingTaskLedger) -> [String] {
            let value = item.minimum
            var problems: [String] = []
            if value < min {
                problems.append("minimum \(value) is below \(min)")
            }
            if value > max {
                problems.append("minimum \(value) is above \(max)")
            }
            return problems
        }
    }

    final class RollingTaskLedgerAllergyLengthRule: RollingTaskLedgerRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: RollingTaskLedger) -> [String] {
            let size = item.allergy.count
            if size > maxLength {
                return ["allergy is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class RollingTaskLedgerRequiredAllergyRule: RollingTaskLedgerRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: RollingTaskLedger) -> [String] {
            if item.allergy.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class RollingTaskLedgerCopayRangeRule: RollingTaskLedgerRule {
        var min: Double
        var max: Double

        init(min: Double, max: Double) {
            self.min = min
            self.max = max
        }

        func check(_ item: RollingTaskLedger) -> [String] {
            let value = item.copay
            if value < min || value > max {
                return ["copay \(value) is outside \(min) to \(max)"]
            }
            return []
        }
    }

    /// Runs every rule of a rolling task ledger.
    final class RollingTaskLedgerValidator {
        var rules: [any RollingTaskLedgerRule]

        init(rules: [any RollingTaskLedgerRule]) {
            self.rules = rules
        }

        func validate(_ item: RollingTaskLedger) -> [String] {
            var problems: [String] = []
            for rule in rules {
                for problem in rule.check(item) {
                    problems.append(problem)
                }
            }
            return problems
        }

        func requireValid(_ item: RollingTaskLedger) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.label()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [RollingTaskLedger]) -> [String: [String]] {
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

    static func defaultRollingTaskLedgerValidator() -> RollingTaskLedgerValidator {
        return RollingTaskLedgerValidator(
            rules: [
                RollingTaskLedgerMinimumRangeRule(min: 4.6, max: 432.3),
                RollingTaskLedgerAllergyLengthRule(maxLength: 80),
                RollingTaskLedgerRequiredAllergyRule(message: "rolling task ledger needs this field"),
                RollingTaskLedgerCopayRangeRule(min: 0.9, max: 3228.0),
            ]
        )
    }
}
