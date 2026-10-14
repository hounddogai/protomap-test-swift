import AcmePlatform
import Foundation

extension Referrals {
    /// A rule a follow up override must pass. Check returns its problems, or none.
    protocol FollowUpOverrideRule {
        func check(_ item: FollowUpOverride) -> [String]
    }

    final class FollowUpOverrideCopayRangeRule: FollowUpOverrideRule {
        var min: Double
        var max: Double

        init(min: Double, max: Double) {
            self.min = min
            self.max = max
        }

        func check(_ item: FollowUpOverride) -> [String] {
            let value = item.copay
            if value < min || value > max {
                return ["copay \(value) is outside \(min) to \(max)"]
            }
            return []
        }
    }

    final class FollowUpOverridePatientRefLengthRule: FollowUpOverrideRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: FollowUpOverride) -> [String] {
            let size = item.patientRef.count
            if size > maxLength {
                return ["patient ref is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class FollowUpOverrideCodeLengthRule: FollowUpOverrideRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: FollowUpOverride) -> [String] {
            let size = item.code.count
            if size > maxLength {
                return ["code is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class FollowUpOverrideDiagnosisCodeLengthRule: FollowUpOverrideRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: FollowUpOverride) -> [String] {
            let size = item.diagnosisCode.count
            if size > maxLength {
                return ["diagnosis code is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class FollowUpOverrideRequiredCodeRule: FollowUpOverrideRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: FollowUpOverride) -> [String] {
            if item.code.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    /// Runs every rule of a follow up override.
    final class FollowUpOverrideValidator {
        var rules: [any FollowUpOverrideRule]

        init(rules: [any FollowUpOverrideRule]) {
            self.rules = rules
        }

        func validate(_ item: FollowUpOverride) -> [String] {
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

        func requireValid(_ item: FollowUpOverride) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.displayLabel()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [FollowUpOverride]) -> [String: [String]] {
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

    static func defaultFollowUpOverrideValidator() -> FollowUpOverrideValidator {
        return FollowUpOverrideValidator(
            rules: [
                FollowUpOverrideCopayRangeRule(min: 5.1, max: 890.6),
                FollowUpOverridePatientRefLengthRule(maxLength: 80),
                FollowUpOverrideCodeLengthRule(maxLength: 16),
                FollowUpOverrideDiagnosisCodeLengthRule(maxLength: 3600),
                FollowUpOverrideRequiredCodeRule(message: "follow up override needs a value"),
            ]
        )
    }
}
