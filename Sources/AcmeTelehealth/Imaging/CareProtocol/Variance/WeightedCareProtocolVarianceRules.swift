import AcmePlatform
import Foundation

extension Imaging {
    /// A rule a weighted care protocol variance must pass. Check returns its problems, or none.
    protocol WeightedCareProtocolVarianceRule {
        func check(_ item: WeightedCareProtocolVariance) -> [String]
    }

    final class WeightedCareProtocolVarianceWeightRangeRule: WeightedCareProtocolVarianceRule {
        var min: Double
        var max: Double

        init(min: Double, max: Double) {
            self.min = min
            self.max = max
        }

        func check(_ item: WeightedCareProtocolVariance) -> [String] {
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

    final class WeightedCareProtocolVarianceRequiredPayerRule: WeightedCareProtocolVarianceRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: WeightedCareProtocolVariance) -> [String] {
            if item.payer.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class WeightedCareProtocolVariancePayerLengthRule: WeightedCareProtocolVarianceRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: WeightedCareProtocolVariance) -> [String] {
            let size = item.payer.count
            if size > maxLength {
                return ["payer is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class WeightedCareProtocolVarianceRatioRangeRule: WeightedCareProtocolVarianceRule {
        var min: Double
        var max: Double

        init(min: Double, max: Double) {
            self.min = min
            self.max = max
        }

        func check(_ item: WeightedCareProtocolVariance) -> [String] {
            let value = item.ratio
            if value < min || value > max {
                return ["ratio \(value) is outside \(min) to \(max)"]
            }
            return []
        }
    }

    /// Runs every rule of a weighted care protocol variance.
    final class WeightedCareProtocolVarianceValidator {
        var rules: [any WeightedCareProtocolVarianceRule]

        init(rules: [any WeightedCareProtocolVarianceRule]) {
            self.rules = rules
        }

        func validate(_ item: WeightedCareProtocolVariance) -> [String] {
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

        func requireValid(_ item: WeightedCareProtocolVariance) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.label()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [WeightedCareProtocolVariance]) -> [String: [String]] {
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

    static func defaultWeightedCareProtocolVarianceValidator() -> WeightedCareProtocolVarianceValidator {
        return WeightedCareProtocolVarianceValidator(
            rules: [
                WeightedCareProtocolVarianceWeightRangeRule(min: 2.1, max: 1588.8),
                WeightedCareProtocolVarianceRequiredPayerRule(
                    message: "weighted care protocol variance needs an entry"
                ),
                WeightedCareProtocolVariancePayerLengthRule(maxLength: 80),
                WeightedCareProtocolVarianceRatioRangeRule(min: 2.5, max: 3628.4),
            ]
        )
    }
}
