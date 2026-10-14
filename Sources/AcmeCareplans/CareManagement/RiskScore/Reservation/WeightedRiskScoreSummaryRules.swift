import AcmePlatform
import Foundation

extension CareManagement {
    /// A rule a weighted risk score summary must pass. Check returns its problems, or none.
    protocol WeightedRiskScoreSummaryRule {
        func check(_ item: WeightedRiskScoreSummary) -> [String]
    }

    final class WeightedRiskScoreSummaryRequiredContactEmailRule: WeightedRiskScoreSummaryRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: WeightedRiskScoreSummary) -> [String] {
            if item.contactEmail.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class WeightedRiskScoreSummaryCodePrefixRule: WeightedRiskScoreSummaryRule {
        var prefix: String

        init(prefix: String) {
            self.prefix = prefix
        }

        func check(_ item: WeightedRiskScoreSummary) -> [String] {
            if !item.code.uppercased().hasPrefix(prefix.uppercased()) {
                return ["code must start with \(prefix)"]
            }
            return []
        }
    }

    final class WeightedRiskScoreSummaryPhoneLengthRule: WeightedRiskScoreSummaryRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: WeightedRiskScoreSummary) -> [String] {
            let size = item.phone.count
            if size > maxLength {
                return ["phone is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class WeightedRiskScoreSummaryContactEmailLengthRule: WeightedRiskScoreSummaryRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: WeightedRiskScoreSummary) -> [String] {
            let size = item.contactEmail.count
            if size > maxLength {
                return ["contact email is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class WeightedRiskScoreSummaryLabelLengthRule: WeightedRiskScoreSummaryRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: WeightedRiskScoreSummary) -> [String] {
            let size = item.label.count
            if size > maxLength {
                return ["label is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    /// Runs every rule of a weighted risk score summary.
    final class WeightedRiskScoreSummaryValidator {
        var rules: [any WeightedRiskScoreSummaryRule]

        init(rules: [any WeightedRiskScoreSummaryRule]) {
            self.rules = rules
        }

        func validate(_ item: WeightedRiskScoreSummary) -> [String] {
            var problems: [String] = []
            for rule in rules {
                for problem in rule.check(item) {
                    problems.append(problem)
                }
            }
            return problems
        }

        func requireValid(_ item: WeightedRiskScoreSummary) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.displayLabel()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [WeightedRiskScoreSummary]) -> [String: [String]] {
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

    static func defaultWeightedRiskScoreSummaryValidator() -> WeightedRiskScoreSummaryValidator {
        return WeightedRiskScoreSummaryValidator(
            rules: [
                WeightedRiskScoreSummaryRequiredContactEmailRule(
                    message: "weighted risk score summary needs an entry"
                ),
                WeightedRiskScoreSummaryCodePrefixRule(prefix: "ACM"),
                WeightedRiskScoreSummaryPhoneLengthRule(maxLength: 80),
                WeightedRiskScoreSummaryContactEmailLengthRule(maxLength: 120),
                WeightedRiskScoreSummaryLabelLengthRule(maxLength: 3600),
            ]
        )
    }
}
