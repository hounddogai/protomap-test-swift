import AcmePlatform
import Foundation

extension Consent {
    /// A rule a capped witness plan must pass. Check returns its problems, or none.
    protocol CappedWitnessPlanRule {
        func check(_ item: CappedWitnessPlan) -> [String]
    }

    final class CappedWitnessPlanCodeLengthRule: CappedWitnessPlanRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: CappedWitnessPlan) -> [String] {
            let size = item.code.count
            if size > maxLength {
                return ["code is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class CappedWitnessPlanDiscountRangeRule: CappedWitnessPlanRule {
        var min: Double
        var max: Double

        init(min: Double, max: Double) {
            self.min = min
            self.max = max
        }

        func check(_ item: CappedWitnessPlan) -> [String] {
            let value = item.discount
            if value < min || value > max {
                return ["discount \(value) is outside \(min) to \(max)"]
            }
            return []
        }
    }

    final class CappedWitnessPlanScoreRangeRule: CappedWitnessPlanRule {
        var min: Double
        var max: Double

        init(min: Double, max: Double) {
            self.min = min
            self.max = max
        }

        func check(_ item: CappedWitnessPlan) -> [String] {
            let value = item.score
            var problems: [String] = []
            if value < min {
                problems.append("score \(value) is below \(min)")
            }
            if value > max {
                problems.append("score \(value) is above \(max)")
            }
            return problems
        }
    }

    final class CappedWitnessPlanRequiredContactEmailRule: CappedWitnessPlanRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: CappedWitnessPlan) -> [String] {
            if item.contactEmail.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class CappedWitnessPlanMinimumRangeRule: CappedWitnessPlanRule {
        var min: Double
        var max: Double

        init(min: Double, max: Double) {
            self.min = min
            self.max = max
        }

        func check(_ item: CappedWitnessPlan) -> [String] {
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

    final class CappedWitnessPlanCopayRangeRule: CappedWitnessPlanRule {
        var min: Double
        var max: Double

        init(min: Double, max: Double) {
            self.min = min
            self.max = max
        }

        func check(_ item: CappedWitnessPlan) -> [String] {
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

    /// Runs every rule of a capped witness plan.
    final class CappedWitnessPlanValidator {
        var rules: [any CappedWitnessPlanRule]

        init(rules: [any CappedWitnessPlanRule]) {
            self.rules = rules
        }

        func validate(_ item: CappedWitnessPlan) -> [String] {
            var problems: [String] = []
            for rule in rules {
                for problem in rule.check(item) {
                    problems.append(problem)
                }
            }
            return problems
        }

        func requireValid(_ item: CappedWitnessPlan) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.label()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [CappedWitnessPlan]) -> [String: [String]] {
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

    static func defaultCappedWitnessPlanValidator() -> CappedWitnessPlanValidator {
        return CappedWitnessPlanValidator(
            rules: [
                CappedWitnessPlanCodeLengthRule(maxLength: 64),
                CappedWitnessPlanDiscountRangeRule(min: 7.7, max: 3809.1),
                CappedWitnessPlanScoreRangeRule(min: 5.1, max: 2527.3),
                CappedWitnessPlanRequiredContactEmailRule(message: "capped witness plan needs an entry"),
                CappedWitnessPlanMinimumRangeRule(min: 9.5, max: 2342.5),
                CappedWitnessPlanCopayRangeRule(min: 0.9, max: 686.3),
            ]
        )
    }
}
