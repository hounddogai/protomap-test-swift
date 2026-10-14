import AcmePlatform
import Foundation

extension BedManagement {
    /// A rule a weighted transfer target must pass. Check returns its problems, or none.
    protocol WeightedTransferTargetRule {
        func check(_ item: WeightedTransferTarget) -> [String]
    }

    final class WeightedTransferTargetRequiredLocaleRule: WeightedTransferTargetRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: WeightedTransferTarget) -> [String] {
            if item.locale.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class WeightedTransferTargetCodePrefixRule: WeightedTransferTargetRule {
        var prefix: String

        init(prefix: String) {
            self.prefix = prefix
        }

        func check(_ item: WeightedTransferTarget) -> [String] {
            if !item.code.uppercased().hasPrefix(prefix.uppercased()) {
                return ["code must start with \(prefix)"]
            }
            return []
        }
    }

    final class WeightedTransferTargetCeilingRangeRule: WeightedTransferTargetRule {
        var min: Double
        var max: Double

        init(min: Double, max: Double) {
            self.min = min
            self.max = max
        }

        func check(_ item: WeightedTransferTarget) -> [String] {
            let value = item.ceiling
            if value < min || value > max {
                return ["ceiling \(value) is outside \(min) to \(max)"]
            }
            return []
        }
    }

    final class WeightedTransferTargetRequiredCodeRule: WeightedTransferTargetRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: WeightedTransferTarget) -> [String] {
            if item.code.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    /// Runs every rule of a weighted transfer target.
    final class WeightedTransferTargetValidator {
        var rules: [any WeightedTransferTargetRule]

        init(rules: [any WeightedTransferTargetRule]) {
            self.rules = rules
        }

        func validate(_ item: WeightedTransferTarget) -> [String] {
            var problems: [String] = []
            for rule in rules {
                for problem in rule.check(item) {
                    problems.append(problem)
                }
            }
            return problems
        }

        func requireValid(_ item: WeightedTransferTarget) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.displayLabel()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [WeightedTransferTarget]) -> [String: [String]] {
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

    static func defaultWeightedTransferTargetValidator() -> WeightedTransferTargetValidator {
        return WeightedTransferTargetValidator(
            rules: [
                WeightedTransferTargetRequiredLocaleRule(message: "weighted transfer target needs this field"),
                WeightedTransferTargetCodePrefixRule(prefix: "ACM"),
                WeightedTransferTargetCeilingRangeRule(min: 5.9, max: 3364.4),
                WeightedTransferTargetRequiredCodeRule(message: "weighted transfer target needs a value"),
            ]
        )
    }
}
