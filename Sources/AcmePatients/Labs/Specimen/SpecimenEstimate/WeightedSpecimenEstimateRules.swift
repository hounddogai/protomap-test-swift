import AcmePlatform
import Foundation

extension Labs {
    /// A rule a weighted specimen estimate must pass. Check returns its problems, or none.
    protocol WeightedSpecimenEstimateRule {
        func check(_ item: WeightedSpecimenEstimate) -> [String]
    }

    final class WeightedSpecimenEstimateNameLengthRule: WeightedSpecimenEstimateRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: WeightedSpecimenEstimate) -> [String] {
            let size = item.name.count
            if size > maxLength {
                return ["name is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class WeightedSpecimenEstimateMinimumRangeRule: WeightedSpecimenEstimateRule {
        var min: Double
        var max: Double

        init(min: Double, max: Double) {
            self.min = min
            self.max = max
        }

        func check(_ item: WeightedSpecimenEstimate) -> [String] {
            let value = item.minimum
            if value < min || value > max {
                return ["minimum \(value) is outside \(min) to \(max)"]
            }
            return []
        }
    }

    final class WeightedSpecimenEstimateRequiredNameRule: WeightedSpecimenEstimateRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: WeightedSpecimenEstimate) -> [String] {
            if item.name.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class WeightedSpecimenEstimateAcuityRangeRule: WeightedSpecimenEstimateRule {
        var min: Int
        var max: Int

        init(min: Int, max: Int) {
            self.min = min
            self.max = max
        }

        func check(_ item: WeightedSpecimenEstimate) -> [String] {
            let value = item.acuity
            if value < min || value > max {
                return ["acuity \(value) is outside \(min) to \(max)"]
            }
            return []
        }
    }

    final class WeightedSpecimenEstimateCodePrefixRule: WeightedSpecimenEstimateRule {
        var prefix: String

        init(prefix: String) {
            self.prefix = prefix
        }

        func check(_ item: WeightedSpecimenEstimate) -> [String] {
            if !item.code.uppercased().hasPrefix(prefix.uppercased()) {
                return ["code must start with \(prefix)"]
            }
            return []
        }
    }

    /// Runs every rule of a weighted specimen estimate.
    final class WeightedSpecimenEstimateValidator {
        var rules: [any WeightedSpecimenEstimateRule]

        init(rules: [any WeightedSpecimenEstimateRule]) {
            self.rules = rules
        }

        func validate(_ item: WeightedSpecimenEstimate) -> [String] {
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

        func requireValid(_ item: WeightedSpecimenEstimate) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.label()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [WeightedSpecimenEstimate]) -> [String: [String]] {
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

    static func defaultWeightedSpecimenEstimateValidator() -> WeightedSpecimenEstimateValidator {
        return WeightedSpecimenEstimateValidator(
            rules: [
                WeightedSpecimenEstimateNameLengthRule(maxLength: 1000),
                WeightedSpecimenEstimateMinimumRangeRule(min: 5.3, max: 2743.6),
                WeightedSpecimenEstimateRequiredNameRule(message: "weighted specimen estimate needs an entry"),
                WeightedSpecimenEstimateAcuityRangeRule(min: 120, max: 255),
                WeightedSpecimenEstimateCodePrefixRule(prefix: "Q"),
            ]
        )
    }
}
