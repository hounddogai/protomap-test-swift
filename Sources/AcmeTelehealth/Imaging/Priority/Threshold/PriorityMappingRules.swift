import AcmePlatform
import Foundation

extension Imaging {
    /// A rule a priority mapping must pass. Check returns its problems, or none.
    protocol PriorityMappingRule {
        func check(_ item: PriorityMapping) -> [String]
    }

    final class PriorityMappingRequiredNameRule: PriorityMappingRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: PriorityMapping) -> [String] {
            if item.name.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class PriorityMappingCategoryLengthRule: PriorityMappingRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: PriorityMapping) -> [String] {
            let size = item.category.count
            if size > maxLength {
                return ["category is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class PriorityMappingCodePrefixRule: PriorityMappingRule {
        var prefix: String

        init(prefix: String) {
            self.prefix = prefix
        }

        func check(_ item: PriorityMapping) -> [String] {
            if !item.code.uppercased().hasPrefix(prefix.uppercased()) {
                return ["code must start with \(prefix)"]
            }
            return []
        }
    }

    final class PriorityMappingRequiredCategoryRule: PriorityMappingRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: PriorityMapping) -> [String] {
            if item.category.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class PriorityMappingBatchSizeRangeRule: PriorityMappingRule {
        var min: Int
        var max: Int

        init(min: Int, max: Int) {
            self.min = min
            self.max = max
        }

        func check(_ item: PriorityMapping) -> [String] {
            let value = item.batchSize
            var problems: [String] = []
            if value < min {
                problems.append("batch size \(value) is below \(min)")
            }
            if value > max {
                problems.append("batch size \(value) is above \(max)")
            }
            return problems
        }
    }

    final class PriorityMappingRatioRangeRule: PriorityMappingRule {
        var min: Double
        var max: Double

        init(min: Double, max: Double) {
            self.min = min
            self.max = max
        }

        func check(_ item: PriorityMapping) -> [String] {
            let value = item.ratio
            if value < min || value > max {
                return ["ratio \(value) is outside \(min) to \(max)"]
            }
            return []
        }
    }

    /// Runs every rule of a priority mapping.
    final class PriorityMappingValidator {
        var rules: [any PriorityMappingRule]

        init(rules: [any PriorityMappingRule]) {
            self.rules = rules
        }

        func validate(_ item: PriorityMapping) -> [String] {
            var problems: [String] = []
            for rule in rules {
                for problem in rule.check(item) {
                    problems.append(problem)
                }
            }
            return problems
        }

        func requireValid(_ item: PriorityMapping) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.label()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [PriorityMapping]) -> [String: [String]] {
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

    static func defaultPriorityMappingValidator() -> PriorityMappingValidator {
        return PriorityMappingValidator(
            rules: [
                PriorityMappingRequiredNameRule(message: "priority mapping needs a value"),
                PriorityMappingCategoryLengthRule(maxLength: 32),
                PriorityMappingCodePrefixRule(prefix: "OPS"),
                PriorityMappingRequiredCategoryRule(message: "priority mapping needs a value"),
                PriorityMappingBatchSizeRangeRule(min: 255, max: 3600),
                PriorityMappingRatioRangeRule(min: 1.4, max: 4590.3),
            ]
        )
    }
}
