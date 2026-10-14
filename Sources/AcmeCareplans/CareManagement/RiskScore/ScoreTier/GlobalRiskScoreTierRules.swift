import AcmePlatform
import Foundation

extension CareManagement {
    /// A rule a global risk score tier must pass. Check returns its problems, or none.
    protocol GlobalRiskScoreTierRule {
        func check(_ item: GlobalRiskScoreTier) -> [String]
    }

    final class GlobalRiskScoreTierAllowedLabelRule: GlobalRiskScoreTierRule {
        var allowed: [String]

        init(allowed: [String]) {
            self.allowed = allowed
        }

        func check(_ item: GlobalRiskScoreTier) -> [String] {
            if allowed.count == 0 {
                return []
            }
            if !allowed.contains(Kit.Text.normalize(item.label)) {
                return ["label \(item.label) is missing"]
            }
            return []
        }
    }

    final class GlobalRiskScoreTierTitleLengthRule: GlobalRiskScoreTierRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: GlobalRiskScoreTier) -> [String] {
            let size = item.title.count
            if size > maxLength {
                return ["title is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class GlobalRiskScoreTierRequiredLabelRule: GlobalRiskScoreTierRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: GlobalRiskScoreTier) -> [String] {
            if item.label.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class GlobalRiskScoreTierLabelLengthRule: GlobalRiskScoreTierRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: GlobalRiskScoreTier) -> [String] {
            let size = item.label.count
            if size > maxLength {
                return ["label is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    /// Runs every rule of a global risk score tier.
    final class GlobalRiskScoreTierValidator {
        var rules: [any GlobalRiskScoreTierRule]

        init(rules: [any GlobalRiskScoreTierRule]) {
            self.rules = rules
        }

        func validate(_ item: GlobalRiskScoreTier) -> [String] {
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

        func requireValid(_ item: GlobalRiskScoreTier) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.displayLabel()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [GlobalRiskScoreTier]) -> [String: [String]] {
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

    static func defaultGlobalRiskScoreTierValidator() -> GlobalRiskScoreTierValidator {
        return GlobalRiskScoreTierValidator(
            rules: [
                GlobalRiskScoreTierAllowedLabelRule(allowed: ["rolling", "default", "seasonal"]),
                GlobalRiskScoreTierTitleLengthRule(maxLength: 1000),
                GlobalRiskScoreTierRequiredLabelRule(message: "global risk score tier needs this field"),
                GlobalRiskScoreTierLabelLengthRule(maxLength: 255),
            ]
        )
    }
}
