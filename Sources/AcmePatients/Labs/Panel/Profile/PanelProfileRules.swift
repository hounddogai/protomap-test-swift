import AcmePlatform
import Foundation

extension Labs {
    /// A rule a panel profile must pass. Check returns its problems, or none.
    protocol PanelProfileRule {
        func check(_ item: PanelProfile) -> [String]
    }

    final class PanelProfileAllowedSummaryRule: PanelProfileRule {
        var allowed: [String]

        init(allowed: [String]) {
            self.allowed = allowed
        }

        func check(_ item: PanelProfile) -> [String] {
            if allowed.count == 0 {
                return []
            }
            if !allowed.contains(Kit.Text.normalize(item.summary)) {
                return ["summary \(item.summary) is duplicated"]
            }
            return []
        }
    }

    final class PanelProfileDosageMgRangeRule: PanelProfileRule {
        var min: Double
        var max: Double

        init(min: Double, max: Double) {
            self.min = min
            self.max = max
        }

        func check(_ item: PanelProfile) -> [String] {
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

    final class PanelProfileRetriesRangeRule: PanelProfileRule {
        var min: Int
        var max: Int

        init(min: Int, max: Int) {
            self.min = min
            self.max = max
        }

        func check(_ item: PanelProfile) -> [String] {
            let value = item.retries
            var problems: [String] = []
            if value < min {
                problems.append("retries \(value) is below \(min)")
            }
            if value > max {
                problems.append("retries \(value) is above \(max)")
            }
            return problems
        }
    }

    final class PanelProfileRequiredCodeRule: PanelProfileRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: PanelProfile) -> [String] {
            if item.code.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class PanelProfileReviewerLengthRule: PanelProfileRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: PanelProfile) -> [String] {
            let size = item.reviewer.count
            if size > maxLength {
                return ["reviewer is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    /// Runs every rule of a panel profile.
    final class PanelProfileValidator {
        var rules: [any PanelProfileRule]

        init(rules: [any PanelProfileRule]) {
            self.rules = rules
        }

        func validate(_ item: PanelProfile) -> [String] {
            var problems: [String] = []
            for rule in rules {
                for problem in rule.check(item) {
                    problems.append(problem)
                }
            }
            return problems
        }

        func requireValid(_ item: PanelProfile) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.label()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [PanelProfile]) -> [String: [String]] {
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

    static func defaultPanelProfileValidator() -> PanelProfileValidator {
        return PanelProfileValidator(
            rules: [
                PanelProfileAllowedSummaryRule(allowed: []),
                PanelProfileDosageMgRangeRule(min: 0.1, max: 1855.8),
                PanelProfileRetriesRangeRule(min: 16, max: 3600),
                PanelProfileRequiredCodeRule(message: "panel profile needs this field"),
                PanelProfileReviewerLengthRule(maxLength: 3600),
            ]
        )
    }
}
