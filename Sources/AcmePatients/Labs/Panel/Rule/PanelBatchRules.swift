import AcmePlatform
import Foundation

extension Labs {
    /// A rule a panel batch must pass. Check returns its problems, or none.
    protocol PanelBatchRule {
        func check(_ item: PanelBatch) -> [String]
    }

    final class PanelBatchUnitLengthRule: PanelBatchRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: PanelBatch) -> [String] {
            let size = item.unit.count
            if size > maxLength {
                return ["unit is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class PanelBatchAttemptsRangeRule: PanelBatchRule {
        var min: Int
        var max: Int

        init(min: Int, max: Int) {
            self.min = min
            self.max = max
        }

        func check(_ item: PanelBatch) -> [String] {
            let value = item.attempts
            var problems: [String] = []
            if value < min {
                problems.append("attempts \(value) is below \(min)")
            }
            if value > max {
                problems.append("attempts \(value) is above \(max)")
            }
            return problems
        }
    }

    final class PanelBatchDosageMgRangeRule: PanelBatchRule {
        var min: Double
        var max: Double

        init(min: Double, max: Double) {
            self.min = min
            self.max = max
        }

        func check(_ item: PanelBatch) -> [String] {
            let value = item.dosageMg
            var problems: [String] = []
            if value < min {
                problems.append("dosage mg \(value) is below \(min)")
            }
            if value > max {
                problems.append("dosage mg \(value) is above \(max)")
            }
            return problems
        }
    }

    final class PanelBatchRequiredUnitRule: PanelBatchRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: PanelBatch) -> [String] {
            if item.unit.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class PanelBatchCodePrefixRule: PanelBatchRule {
        var prefix: String

        init(prefix: String) {
            self.prefix = prefix
        }

        func check(_ item: PanelBatch) -> [String] {
            if !item.code.uppercased().hasPrefix(prefix.uppercased()) {
                return ["code must start with \(prefix)"]
            }
            return []
        }
    }

    /// Runs every rule of a panel batch.
    final class PanelBatchValidator {
        var rules: [any PanelBatchRule]

        init(rules: [any PanelBatchRule]) {
            self.rules = rules
        }

        func validate(_ item: PanelBatch) -> [String] {
            var problems: [String] = []
            for rule in rules {
                for problem in rule.check(item) {
                    problems.append(problem)
                }
            }
            return problems
        }

        func requireValid(_ item: PanelBatch) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.displayLabel()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [PanelBatch]) -> [String: [String]] {
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

    static func defaultPanelBatchValidator() -> PanelBatchValidator {
        return PanelBatchValidator(
            rules: [
                PanelBatchUnitLengthRule(maxLength: 32),
                PanelBatchAttemptsRangeRule(min: 80, max: 120),
                PanelBatchDosageMgRangeRule(min: 6.8, max: 679.0),
                PanelBatchRequiredUnitRule(message: "panel batch needs this field"),
                PanelBatchCodePrefixRule(prefix: "ACM"),
            ]
        )
    }
}
