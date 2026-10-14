import AcmePlatform
import Foundation

extension ClinicalOps {
    /// A rule a order set tier must pass. Check returns its problems, or none.
    protocol OrderSetTierRule {
        func check(_ item: OrderSetTier) -> [String]
    }

    final class OrderSetTierCapacityRangeRule: OrderSetTierRule {
        var min: Int
        var max: Int

        init(min: Int, max: Int) {
            self.min = min
            self.max = max
        }

        func check(_ item: OrderSetTier) -> [String] {
            let value = item.capacity
            var problems: [String] = []
            if value < min {
                problems.append("capacity \(value) is below \(min)")
            }
            if value > max {
                problems.append("capacity \(value) is above \(max)")
            }
            return problems
        }
    }

    final class OrderSetTierCodeLengthRule: OrderSetTierRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: OrderSetTier) -> [String] {
            let size = item.code.count
            if size > maxLength {
                return ["code is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class OrderSetTierRequiredLabelRule: OrderSetTierRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: OrderSetTier) -> [String] {
            if item.label.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class OrderSetTierScoreRangeRule: OrderSetTierRule {
        var min: Double
        var max: Double

        init(min: Double, max: Double) {
            self.min = min
            self.max = max
        }

        func check(_ item: OrderSetTier) -> [String] {
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

    final class OrderSetTierRequiredDiagnosisCodeRule: OrderSetTierRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: OrderSetTier) -> [String] {
            if item.diagnosisCode.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class OrderSetTierRequiredDescriptionRule: OrderSetTierRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: OrderSetTier) -> [String] {
            if item.description.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    /// Runs every rule of a order set tier.
    final class OrderSetTierValidator {
        var rules: [any OrderSetTierRule]

        init(rules: [any OrderSetTierRule]) {
            self.rules = rules
        }

        func validate(_ item: OrderSetTier) -> [String] {
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

        func requireValid(_ item: OrderSetTier) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.displayLabel()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [OrderSetTier]) -> [String: [String]] {
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

    static func defaultOrderSetTierValidator() -> OrderSetTierValidator {
        return OrderSetTierValidator(
            rules: [
                OrderSetTierCapacityRangeRule(min: 16, max: 86400),
                OrderSetTierCodeLengthRule(maxLength: 32),
                OrderSetTierRequiredLabelRule(message: "order set tier needs an entry"),
                OrderSetTierScoreRangeRule(min: 8.3, max: 1805.6),
                OrderSetTierRequiredDiagnosisCodeRule(message: "order set tier needs a value"),
                OrderSetTierRequiredDescriptionRule(message: "order set tier needs an entry"),
            ]
        )
    }
}
