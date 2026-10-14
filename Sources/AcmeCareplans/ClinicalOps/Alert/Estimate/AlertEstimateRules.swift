import AcmePlatform
import Foundation

extension ClinicalOps {
    /// A rule a alert estimate must pass. Check returns its problems, or none.
    protocol AlertEstimateRule {
        func check(_ item: AlertEstimate) -> [String]
    }

    final class AlertEstimateCreatedAtRangeRule: AlertEstimateRule {
        var min: Int
        var max: Int

        init(min: Int, max: Int) {
            self.min = min
            self.max = max
        }

        func check(_ item: AlertEstimate) -> [String] {
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

    final class AlertEstimateProcedureCodeLengthRule: AlertEstimateRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: AlertEstimate) -> [String] {
            let size = item.procedureCode.count
            if size > maxLength {
                return ["procedure code is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class AlertEstimateRequiredLabelRule: AlertEstimateRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: AlertEstimate) -> [String] {
            if item.label.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class AlertEstimateCodePrefixRule: AlertEstimateRule {
        var prefix: String

        init(prefix: String) {
            self.prefix = prefix
        }

        func check(_ item: AlertEstimate) -> [String] {
            if !item.code.uppercased().hasPrefix(prefix.uppercased()) {
                return ["code must start with \(prefix)"]
            }
            return []
        }
    }

    /// Runs every rule of a alert estimate.
    final class AlertEstimateValidator {
        var rules: [any AlertEstimateRule]

        init(rules: [any AlertEstimateRule]) {
            self.rules = rules
        }

        func validate(_ item: AlertEstimate) -> [String] {
            var problems: [String] = []
            for rule in rules {
                for problem in rule.check(item) {
                    problems.append(problem)
                }
            }
            return problems
        }

        func requireValid(_ item: AlertEstimate) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.displayLabel()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [AlertEstimate]) -> [String: [String]] {
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

    static func defaultAlertEstimateValidator() -> AlertEstimateValidator {
        return AlertEstimateValidator(
            rules: [
                AlertEstimateCreatedAtRangeRule(min: 120, max: 1000),
                AlertEstimateProcedureCodeLengthRule(maxLength: 64),
                AlertEstimateRequiredLabelRule(message: "alert estimate needs a value"),
                AlertEstimateCodePrefixRule(prefix: "ACM"),
            ]
        )
    }
}
