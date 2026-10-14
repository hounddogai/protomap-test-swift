import AcmePlatform
import Foundation

extension RevenueCycle {
    /// A rule a strict claim override must pass. Check returns its problems, or none.
    protocol StrictClaimOverrideRule {
        func check(_ item: StrictClaimOverride) -> [String]
    }

    final class StrictClaimOverrideRequiredSummaryRule: StrictClaimOverrideRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: StrictClaimOverride) -> [String] {
            if item.summary.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class StrictClaimOverrideSequenceRangeRule: StrictClaimOverrideRule {
        var min: Int
        var max: Int

        init(min: Int, max: Int) {
            self.min = min
            self.max = max
        }

        func check(_ item: StrictClaimOverride) -> [String] {
            let value = item.sequence
            if value < min || value > max {
                return ["sequence \(value) is outside \(min) to \(max)"]
            }
            return []
        }
    }

    final class StrictClaimOverrideRequiredFacilityRule: StrictClaimOverrideRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: StrictClaimOverride) -> [String] {
            if item.facility.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class StrictClaimOverrideFacilityLengthRule: StrictClaimOverrideRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: StrictClaimOverride) -> [String] {
            let size = item.facility.count
            if size > maxLength {
                return ["facility is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class StrictClaimOverrideSummaryLengthRule: StrictClaimOverrideRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: StrictClaimOverride) -> [String] {
            let size = item.summary.count
            if size > maxLength {
                return ["summary is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    /// Runs every rule of a strict claim override.
    final class StrictClaimOverrideValidator {
        var rules: [any StrictClaimOverrideRule]

        init(rules: [any StrictClaimOverrideRule]) {
            self.rules = rules
        }

        func validate(_ item: StrictClaimOverride) -> [String] {
            var problems: [String] = []
            for rule in rules {
                for problem in rule.check(item) {
                    problems.append(problem)
                }
            }
            return problems
        }

        func requireValid(_ item: StrictClaimOverride) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.label()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [StrictClaimOverride]) -> [String: [String]] {
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

    static func defaultStrictClaimOverrideValidator() -> StrictClaimOverrideValidator {
        return StrictClaimOverrideValidator(
            rules: [
                StrictClaimOverrideRequiredSummaryRule(message: "strict claim override needs an entry"),
                StrictClaimOverrideSequenceRangeRule(min: 80, max: 1000),
                StrictClaimOverrideRequiredFacilityRule(message: "strict claim override needs this field"),
                StrictClaimOverrideFacilityLengthRule(maxLength: 64),
                StrictClaimOverrideSummaryLengthRule(maxLength: 120),
            ]
        )
    }
}
