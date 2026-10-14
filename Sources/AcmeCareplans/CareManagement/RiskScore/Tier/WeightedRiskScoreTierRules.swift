import AcmePlatform
import Foundation

extension CareManagement {
    /// A rule a weighted risk score tier must pass. Check returns its problems, or none.
    protocol WeightedRiskScoreTierRule {
        func check(_ item: WeightedRiskScoreTier) -> [String]
    }

    final class WeightedRiskScoreTierNotesLengthRule: WeightedRiskScoreTierRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: WeightedRiskScoreTier) -> [String] {
            let size = item.notes.count
            if size > maxLength {
                return ["notes is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class WeightedRiskScoreTierDiscountRangeRule: WeightedRiskScoreTierRule {
        var min: Double
        var max: Double

        init(min: Double, max: Double) {
            self.min = min
            self.max = max
        }

        func check(_ item: WeightedRiskScoreTier) -> [String] {
            let value = item.discount
            if value < min || value > max {
                return ["discount \(value) is outside \(min) to \(max)"]
            }
            return []
        }
    }

    final class WeightedRiskScoreTierCodePrefixRule: WeightedRiskScoreTierRule {
        var prefix: String

        init(prefix: String) {
            self.prefix = prefix
        }

        func check(_ item: WeightedRiskScoreTier) -> [String] {
            if !item.code.uppercased().hasPrefix(prefix.uppercased()) {
                return ["code must start with \(prefix)"]
            }
            return []
        }
    }

    final class WeightedRiskScoreTierRequiredChannelRule: WeightedRiskScoreTierRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: WeightedRiskScoreTier) -> [String] {
            if item.channel.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    /// Runs every rule of a weighted risk score tier.
    final class WeightedRiskScoreTierValidator {
        var rules: [any WeightedRiskScoreTierRule]

        init(rules: [any WeightedRiskScoreTierRule]) {
            self.rules = rules
        }

        func validate(_ item: WeightedRiskScoreTier) -> [String] {
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

        func requireValid(_ item: WeightedRiskScoreTier) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.label()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [WeightedRiskScoreTier]) -> [String: [String]] {
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

    static func defaultWeightedRiskScoreTierValidator() -> WeightedRiskScoreTierValidator {
        return WeightedRiskScoreTierValidator(
            rules: [
                WeightedRiskScoreTierNotesLengthRule(maxLength: 120),
                WeightedRiskScoreTierDiscountRangeRule(min: 1.3, max: 3105.5),
                WeightedRiskScoreTierCodePrefixRule(prefix: "ACM"),
                WeightedRiskScoreTierRequiredChannelRule(message: "weighted risk score tier needs a value"),
            ]
        )
    }
}
