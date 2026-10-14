import AcmePlatform
import Foundation

extension BedManagement {
    /// A rule a fallback transfer template must pass. Check returns its problems, or none.
    protocol FallbackTransferTemplateRule {
        func check(_ item: FallbackTransferTemplate) -> [String]
    }

    final class FallbackTransferTemplateDosageMgRangeRule: FallbackTransferTemplateRule {
        var min: Double
        var max: Double

        init(min: Double, max: Double) {
            self.min = min
            self.max = max
        }

        func check(_ item: FallbackTransferTemplate) -> [String] {
            let value = item.dosageMg
            if value < min || value > max {
                return ["dosage mg \(value) is outside \(min) to \(max)"]
            }
            return []
        }
    }

    final class FallbackTransferTemplateFloorValueRangeRule: FallbackTransferTemplateRule {
        var min: Double
        var max: Double

        init(min: Double, max: Double) {
            self.min = min
            self.max = max
        }

        func check(_ item: FallbackTransferTemplate) -> [String] {
            let value = item.floorValue
            if value < min || value > max {
                return ["floor value \(value) is outside \(min) to \(max)"]
            }
            return []
        }
    }

    final class FallbackTransferTemplateCreatedAtRangeRule: FallbackTransferTemplateRule {
        var min: Int
        var max: Int

        init(min: Int, max: Int) {
            self.min = min
            self.max = max
        }

        func check(_ item: FallbackTransferTemplate) -> [String] {
            let value = item.createdAt
            var problems: [String] = []
            if value < min {
                problems.append("created at \(value) is below \(min)")
            }
            if value > max {
                problems.append("created at \(value) is above \(max)")
            }
            return problems
        }
    }

    final class FallbackTransferTemplateRequiredTitleRule: FallbackTransferTemplateRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: FallbackTransferTemplate) -> [String] {
            if item.title.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    /// Runs every rule of a fallback transfer template.
    final class FallbackTransferTemplateValidator {
        var rules: [any FallbackTransferTemplateRule]

        init(rules: [any FallbackTransferTemplateRule]) {
            self.rules = rules
        }

        func validate(_ item: FallbackTransferTemplate) -> [String] {
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

        func requireValid(_ item: FallbackTransferTemplate) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.label()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [FallbackTransferTemplate]) -> [String: [String]] {
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

    static func defaultFallbackTransferTemplateValidator() -> FallbackTransferTemplateValidator {
        return FallbackTransferTemplateValidator(
            rules: [
                FallbackTransferTemplateDosageMgRangeRule(min: 9.5, max: 3477.6),
                FallbackTransferTemplateFloorValueRangeRule(min: 0.8, max: 2142.0),
                FallbackTransferTemplateCreatedAtRangeRule(min: 32, max: 3600),
                FallbackTransferTemplateRequiredTitleRule(message: "fallback transfer template needs this field"),
            ]
        )
    }
}
