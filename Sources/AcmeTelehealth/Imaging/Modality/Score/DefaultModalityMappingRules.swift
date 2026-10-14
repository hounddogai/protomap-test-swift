import AcmePlatform
import Foundation

extension Imaging {
    /// A rule a default modality mapping must pass. Check returns its problems, or none.
    protocol DefaultModalityMappingRule {
        func check(_ item: DefaultModalityMapping) -> [String]
    }

    final class DefaultModalityMappingRateRangeRule: DefaultModalityMappingRule {
        var min: Double
        var max: Double

        init(min: Double, max: Double) {
            self.min = min
            self.max = max
        }

        func check(_ item: DefaultModalityMapping) -> [String] {
            let value = item.rate
            if value < min || value > max {
                return ["rate \(value) is outside \(min) to \(max)"]
            }
            return []
        }
    }

    final class DefaultModalityMappingRequiredTitleRule: DefaultModalityMappingRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: DefaultModalityMapping) -> [String] {
            if item.title.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class DefaultModalityMappingVersionRangeRule: DefaultModalityMappingRule {
        var min: Int
        var max: Int

        init(min: Int, max: Int) {
            self.min = min
            self.max = max
        }

        func check(_ item: DefaultModalityMapping) -> [String] {
            let value = item.version
            if value < min || value > max {
                return ["version \(value) is outside \(min) to \(max)"]
            }
            return []
        }
    }

    /// Runs every rule of a default modality mapping.
    final class DefaultModalityMappingValidator {
        var rules: [any DefaultModalityMappingRule]

        init(rules: [any DefaultModalityMappingRule]) {
            self.rules = rules
        }

        func validate(_ item: DefaultModalityMapping) -> [String] {
            var problems: [String] = []
            for rule in rules {
                for problem in rule.check(item) {
                    problems.append(problem)
                }
            }
            return problems
        }

        func requireValid(_ item: DefaultModalityMapping) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.label()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [DefaultModalityMapping]) -> [String: [String]] {
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

    static func defaultDefaultModalityMappingValidator() -> DefaultModalityMappingValidator {
        return DefaultModalityMappingValidator(
            rules: [
                DefaultModalityMappingRateRangeRule(min: 5.9, max: 238.8),
                DefaultModalityMappingRequiredTitleRule(message: "default modality mapping needs this field"),
                DefaultModalityMappingVersionRangeRule(min: 64, max: 1000),
            ]
        )
    }
}
