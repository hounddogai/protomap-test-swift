import AcmePlatform
import Foundation

extension RevenueCycle {
    /// A rule a weighted remittance request must pass. Check returns its problems, or none.
    protocol WeightedRemittanceRequestRule {
        func check(_ item: WeightedRemittanceRequest) -> [String]
    }

    final class WeightedRemittanceRequestSummaryLengthRule: WeightedRemittanceRequestRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: WeightedRemittanceRequest) -> [String] {
            let size = item.summary.count
            if size > maxLength {
                return ["summary is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class WeightedRemittanceRequestRequiredCodeRule: WeightedRemittanceRequestRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: WeightedRemittanceRequest) -> [String] {
            if item.code.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class WeightedRemittanceRequestCodeLengthRule: WeightedRemittanceRequestRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: WeightedRemittanceRequest) -> [String] {
            let size = item.code.count
            if size > maxLength {
                return ["code is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class WeightedRemittanceRequestExpiresAtRangeRule: WeightedRemittanceRequestRule {
        var min: Int
        var max: Int

        init(min: Int, max: Int) {
            self.min = min
            self.max = max
        }

        func check(_ item: WeightedRemittanceRequest) -> [String] {
            let value = item.expiresAt
            var problems: [String] = []
            if value < min {
                problems.append("expires at \(value) is below \(min)")
            }
            if value > max {
                problems.append("expires at \(value) is above \(max)")
            }
            return problems
        }
    }

    final class WeightedRemittanceRequestRequiredLabelRule: WeightedRemittanceRequestRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: WeightedRemittanceRequest) -> [String] {
            if item.label.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class WeightedRemittanceRequestCodePrefixRule: WeightedRemittanceRequestRule {
        var prefix: String

        init(prefix: String) {
            self.prefix = prefix
        }

        func check(_ item: WeightedRemittanceRequest) -> [String] {
            if !item.code.uppercased().hasPrefix(prefix.uppercased()) {
                return ["code must start with \(prefix)"]
            }
            return []
        }
    }

    /// Runs every rule of a weighted remittance request.
    final class WeightedRemittanceRequestValidator {
        var rules: [any WeightedRemittanceRequestRule]

        init(rules: [any WeightedRemittanceRequestRule]) {
            self.rules = rules
        }

        func validate(_ item: WeightedRemittanceRequest) -> [String] {
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

        func requireValid(_ item: WeightedRemittanceRequest) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.displayLabel()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [WeightedRemittanceRequest]) -> [String: [String]] {
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

    static func defaultWeightedRemittanceRequestValidator() -> WeightedRemittanceRequestValidator {
        return WeightedRemittanceRequestValidator(
            rules: [
                WeightedRemittanceRequestSummaryLengthRule(maxLength: 32),
                WeightedRemittanceRequestRequiredCodeRule(message: "weighted remittance request needs an entry"),
                WeightedRemittanceRequestCodeLengthRule(maxLength: 80),
                WeightedRemittanceRequestExpiresAtRangeRule(min: 80, max: 120),
                WeightedRemittanceRequestRequiredLabelRule(message: "weighted remittance request needs a value"),
                WeightedRemittanceRequestCodePrefixRule(prefix: "ACM"),
            ]
        )
    }
}
