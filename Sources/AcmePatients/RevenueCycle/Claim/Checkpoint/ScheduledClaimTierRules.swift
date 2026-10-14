import AcmePlatform
import Foundation

extension RevenueCycle {
    /// A rule a scheduled claim tier must pass. Check returns its problems, or none.
    protocol ScheduledClaimTierRule {
        func check(_ item: ScheduledClaimTier) -> [String]
    }

    final class ScheduledClaimTierDiagnosisCodeLengthRule: ScheduledClaimTierRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: ScheduledClaimTier) -> [String] {
            let size = item.diagnosisCode.count
            if size > maxLength {
                return ["diagnosis code is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class ScheduledClaimTierRequiredCodeRule: ScheduledClaimTierRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: ScheduledClaimTier) -> [String] {
            if item.code.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class ScheduledClaimTierThresholdRangeRule: ScheduledClaimTierRule {
        var min: Double
        var max: Double

        init(min: Double, max: Double) {
            self.min = min
            self.max = max
        }

        func check(_ item: ScheduledClaimTier) -> [String] {
            let value = item.threshold
            var problems: [String] = []
            if value < min {
                problems.append("threshold \(value) is below \(min)")
            }
            if value > max {
                problems.append("threshold \(value) is above \(max)")
            }
            return problems
        }
    }

    final class ScheduledClaimTierRequiredNameRule: ScheduledClaimTierRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: ScheduledClaimTier) -> [String] {
            if item.name.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    /// Runs every rule of a scheduled claim tier.
    final class ScheduledClaimTierValidator {
        var rules: [any ScheduledClaimTierRule]

        init(rules: [any ScheduledClaimTierRule]) {
            self.rules = rules
        }

        func validate(_ item: ScheduledClaimTier) -> [String] {
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

        func requireValid(_ item: ScheduledClaimTier) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.label()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [ScheduledClaimTier]) -> [String: [String]] {
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

    static func defaultScheduledClaimTierValidator() -> ScheduledClaimTierValidator {
        return ScheduledClaimTierValidator(
            rules: [
                ScheduledClaimTierDiagnosisCodeLengthRule(maxLength: 255),
                ScheduledClaimTierRequiredCodeRule(message: "scheduled claim tier needs an entry"),
                ScheduledClaimTierThresholdRangeRule(min: 3.5, max: 1815.8),
                ScheduledClaimTierRequiredNameRule(message: "scheduled claim tier needs an entry"),
            ]
        )
    }
}
