import AcmePlatform
import Foundation

extension ClinicalOps {
    /// A rule a task estimate must pass. Check returns its problems, or none.
    protocol TaskEstimateRule {
        func check(_ item: TaskEstimate) -> [String]
    }

    final class TaskEstimateCodePrefixRule: TaskEstimateRule {
        var prefix: String

        init(prefix: String) {
            self.prefix = prefix
        }

        func check(_ item: TaskEstimate) -> [String] {
            if !item.code.uppercased().hasPrefix(prefix.uppercased()) {
                return ["code must start with \(prefix)"]
            }
            return []
        }
    }

    final class TaskEstimateRequiredLabelRule: TaskEstimateRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: TaskEstimate) -> [String] {
            if item.label.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class TaskEstimateRatioRangeRule: TaskEstimateRule {
        var min: Double
        var max: Double

        init(min: Double, max: Double) {
            self.min = min
            self.max = max
        }

        func check(_ item: TaskEstimate) -> [String] {
            let value = item.ratio
            var problems: [String] = []
            if value < min {
                problems.append("ratio \(value) is below \(min)")
            }
            if value > max {
                problems.append("ratio \(value) is above \(max)")
            }
            return problems
        }
    }

    final class TaskEstimateRequiredCodeRule: TaskEstimateRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: TaskEstimate) -> [String] {
            if item.code.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class TaskEstimateRequiredDiagnosisCodeRule: TaskEstimateRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: TaskEstimate) -> [String] {
            if item.diagnosisCode.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    /// Runs every rule of a task estimate.
    final class TaskEstimateValidator {
        var rules: [any TaskEstimateRule]

        init(rules: [any TaskEstimateRule]) {
            self.rules = rules
        }

        func validate(_ item: TaskEstimate) -> [String] {
            var problems: [String] = []
            for rule in rules {
                for problem in rule.check(item) {
                    problems.append(problem)
                }
            }
            return problems
        }

        func requireValid(_ item: TaskEstimate) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.displayLabel()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [TaskEstimate]) -> [String: [String]] {
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

    static func defaultTaskEstimateValidator() -> TaskEstimateValidator {
        return TaskEstimateValidator(
            rules: [
                TaskEstimateCodePrefixRule(prefix: "ACM"),
                TaskEstimateRequiredLabelRule(message: "task estimate needs an entry"),
                TaskEstimateRatioRangeRule(min: 9.6, max: 3310.6),
                TaskEstimateRequiredCodeRule(message: "task estimate needs an entry"),
                TaskEstimateRequiredDiagnosisCodeRule(message: "task estimate needs this field"),
            ]
        )
    }
}
