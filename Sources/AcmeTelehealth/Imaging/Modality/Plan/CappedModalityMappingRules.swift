import AcmePlatform
import Foundation

extension Imaging {
    /// A rule a capped modality mapping must pass. Check returns its problems, or none.
    protocol CappedModalityMappingRule {
        func check(_ item: CappedModalityMapping) -> [String]
    }

    final class CappedModalityMappingRequiredCodeRule: CappedModalityMappingRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: CappedModalityMapping) -> [String] {
            if item.code.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class CappedModalityMappingRequiredExternalRefRule: CappedModalityMappingRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: CappedModalityMapping) -> [String] {
            if item.externalRef.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class CappedModalityMappingMarginRangeRule: CappedModalityMappingRule {
        var min: Double
        var max: Double

        init(min: Double, max: Double) {
            self.min = min
            self.max = max
        }

        func check(_ item: CappedModalityMapping) -> [String] {
            let value = item.margin
            var problems: [String] = []
            if value < min {
                problems.append("margin \(value) is below \(min)")
            }
            if value > max {
                problems.append("margin \(value) is above \(max)")
            }
            return problems
        }
    }

    final class CappedModalityMappingExternalRefLengthRule: CappedModalityMappingRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: CappedModalityMapping) -> [String] {
            let size = item.externalRef.count
            if size > maxLength {
                return ["external ref is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    /// Runs every rule of a capped modality mapping.
    final class CappedModalityMappingValidator {
        var rules: [any CappedModalityMappingRule]

        init(rules: [any CappedModalityMappingRule]) {
            self.rules = rules
        }

        func validate(_ item: CappedModalityMapping) -> [String] {
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

        func requireValid(_ item: CappedModalityMapping) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.label()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [CappedModalityMapping]) -> [String: [String]] {
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

    static func defaultCappedModalityMappingValidator() -> CappedModalityMappingValidator {
        return CappedModalityMappingValidator(
            rules: [
                CappedModalityMappingRequiredCodeRule(message: "capped modality mapping needs this field"),
                CappedModalityMappingRequiredExternalRefRule(message: "capped modality mapping needs a value"),
                CappedModalityMappingMarginRangeRule(min: 6.1, max: 182.2),
                CappedModalityMappingExternalRefLengthRule(maxLength: 255),
            ]
        )
    }
}
