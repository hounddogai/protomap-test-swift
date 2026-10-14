import AcmePlatform
import Foundation

extension Referrals {
    /// A rule a weighted eligibility window must pass. Check returns its problems, or none.
    protocol WeightedEligibilityWindowRule {
        func check(_ item: WeightedEligibilityWindow) -> [String]
    }

    final class WeightedEligibilityWindowPinnedGuardRule: WeightedEligibilityWindowRule {
        var limit: Int

        init(limit: Int) {
            self.limit = limit
        }

        func check(_ item: WeightedEligibilityWindow) -> [String] {
            if item.pinned && (item.revision > limit) {
                return ["revision \(item.revision) exceeds \(limit) while pinned"]
            }
            return []
        }
    }

    final class WeightedEligibilityWindowRequiredBedRule: WeightedEligibilityWindowRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: WeightedEligibilityWindow) -> [String] {
            if item.bed.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class WeightedEligibilityWindowRequiredCodeRule: WeightedEligibilityWindowRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: WeightedEligibilityWindow) -> [String] {
            if item.code.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    /// Runs every rule of a weighted eligibility window.
    final class WeightedEligibilityWindowValidator {
        var rules: [any WeightedEligibilityWindowRule]

        init(rules: [any WeightedEligibilityWindowRule]) {
            self.rules = rules
        }

        func validate(_ item: WeightedEligibilityWindow) -> [String] {
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

        func requireValid(_ item: WeightedEligibilityWindow) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.displayLabel()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [WeightedEligibilityWindow]) -> [String: [String]] {
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

    static func defaultWeightedEligibilityWindowValidator() -> WeightedEligibilityWindowValidator {
        return WeightedEligibilityWindowValidator(
            rules: [
                WeightedEligibilityWindowPinnedGuardRule(limit: 120),
                WeightedEligibilityWindowRequiredBedRule(message: "weighted eligibility window needs this field"),
                WeightedEligibilityWindowRequiredCodeRule(message: "weighted eligibility window needs an entry"),
            ]
        )
    }
}
