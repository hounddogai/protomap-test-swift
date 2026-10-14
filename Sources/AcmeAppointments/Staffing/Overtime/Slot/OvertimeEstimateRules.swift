import AcmePlatform
import Foundation

extension Staffing {
    /// A rule a overtime estimate must pass. Check returns its problems, or none.
    protocol OvertimeEstimateRule {
        func check(_ item: OvertimeEstimate) -> [String]
    }

    final class OvertimeEstimateLocaleLengthRule: OvertimeEstimateRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: OvertimeEstimate) -> [String] {
            let size = item.locale.count
            if size > maxLength {
                return ["locale is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class OvertimeEstimateRequiredCodeRule: OvertimeEstimateRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: OvertimeEstimate) -> [String] {
            if item.code.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class OvertimeEstimateRequiredLocaleRule: OvertimeEstimateRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: OvertimeEstimate) -> [String] {
            if item.locale.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class OvertimeEstimateCodePrefixRule: OvertimeEstimateRule {
        var prefix: String

        init(prefix: String) {
            self.prefix = prefix
        }

        func check(_ item: OvertimeEstimate) -> [String] {
            if !item.code.uppercased().hasPrefix(prefix.uppercased()) {
                return ["code must start with \(prefix)"]
            }
            return []
        }
    }

    final class OvertimeEstimateCostRangeRule: OvertimeEstimateRule {
        var min: Double
        var max: Double

        init(min: Double, max: Double) {
            self.min = min
            self.max = max
        }

        func check(_ item: OvertimeEstimate) -> [String] {
            let value = item.cost
            var problems: [String] = []
            if value < min {
                problems.append("cost \(value) is below \(min)")
            }
            if value > max {
                problems.append("cost \(value) is above \(max)")
            }
            return problems
        }
    }

    /// Runs every rule of a overtime estimate.
    final class OvertimeEstimateValidator {
        var rules: [any OvertimeEstimateRule]

        init(rules: [any OvertimeEstimateRule]) {
            self.rules = rules
        }

        func validate(_ item: OvertimeEstimate) -> [String] {
            var problems: [String] = []
            for rule in rules {
                for problem in rule.check(item) {
                    problems.append(problem)
                }
            }
            return problems
        }

        func requireValid(_ item: OvertimeEstimate) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.displayLabel()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [OvertimeEstimate]) -> [String: [String]] {
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

    static func defaultOvertimeEstimateValidator() -> OvertimeEstimateValidator {
        return OvertimeEstimateValidator(
            rules: [
                OvertimeEstimateLocaleLengthRule(maxLength: 255),
                OvertimeEstimateRequiredCodeRule(message: "overtime estimate needs an entry"),
                OvertimeEstimateRequiredLocaleRule(message: "overtime estimate needs an entry"),
                OvertimeEstimateCodePrefixRule(prefix: "X"),
                OvertimeEstimateCostRangeRule(min: 3.1, max: 4649.0),
            ]
        )
    }
}
