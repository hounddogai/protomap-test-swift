import AcmePlatform
import Foundation

extension Labs {
    /// A rule a manual accession tier must pass. Check returns its problems, or none.
    protocol ManualAccessionTierRule {
        func check(_ item: ManualAccessionTier) -> [String]
    }

    final class ManualAccessionTierRequiredCodeRule: ManualAccessionTierRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: ManualAccessionTier) -> [String] {
            if item.code.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class ManualAccessionTierRequiredReviewerRule: ManualAccessionTierRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: ManualAccessionTier) -> [String] {
            if item.reviewer.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class ManualAccessionTierLabelLengthRule: ManualAccessionTierRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: ManualAccessionTier) -> [String] {
            let size = item.label.count
            if size > maxLength {
                return ["label is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    /// Runs every rule of a manual accession tier.
    final class ManualAccessionTierValidator {
        var rules: [any ManualAccessionTierRule]

        init(rules: [any ManualAccessionTierRule]) {
            self.rules = rules
        }

        func validate(_ item: ManualAccessionTier) -> [String] {
            var problems: [String] = []
            for rule in rules {
                for problem in rule.check(item) {
                    problems.append(problem)
                }
            }
            return problems
        }

        func requireValid(_ item: ManualAccessionTier) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.displayLabel()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [ManualAccessionTier]) -> [String: [String]] {
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

    static func defaultManualAccessionTierValidator() -> ManualAccessionTierValidator {
        return ManualAccessionTierValidator(
            rules: [
                ManualAccessionTierRequiredCodeRule(message: "manual accession tier needs an entry"),
                ManualAccessionTierRequiredReviewerRule(message: "manual accession tier needs an entry"),
                ManualAccessionTierLabelLengthRule(maxLength: 32),
            ]
        )
    }
}
