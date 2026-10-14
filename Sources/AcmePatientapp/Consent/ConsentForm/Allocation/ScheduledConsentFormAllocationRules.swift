import AcmePlatform
import Foundation

extension Consent {
    /// A rule a scheduled consent form allocation must pass. Check returns its problems, or none.
    protocol ScheduledConsentFormAllocationRule {
        func check(_ item: ScheduledConsentFormAllocation) -> [String]
    }

    final class ScheduledConsentFormAllocationLabelLengthRule: ScheduledConsentFormAllocationRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: ScheduledConsentFormAllocation) -> [String] {
            let size = item.label.count
            if size > maxLength {
                return ["label is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class ScheduledConsentFormAllocationOwnerIDLengthRule: ScheduledConsentFormAllocationRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: ScheduledConsentFormAllocation) -> [String] {
            let size = item.ownerID.count
            if size > maxLength {
                return ["owner id is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class ScheduledConsentFormAllocationRequiredCodeRule: ScheduledConsentFormAllocationRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: ScheduledConsentFormAllocation) -> [String] {
            if item.code.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class ScheduledConsentFormAllocationDurationMinutesRangeRule: ScheduledConsentFormAllocationRule {
        var min: Int
        var max: Int

        init(min: Int, max: Int) {
            self.min = min
            self.max = max
        }

        func check(_ item: ScheduledConsentFormAllocation) -> [String] {
            let value = item.durationMinutes
            if value < min || value > max {
                return ["duration minutes \(value) is outside \(min) to \(max)"]
            }
            return []
        }
    }

    final class ScheduledConsentFormAllocationSourceLengthRule: ScheduledConsentFormAllocationRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: ScheduledConsentFormAllocation) -> [String] {
            let size = item.source.count
            if size > maxLength {
                return ["source is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    /// Runs every rule of a scheduled consent form allocation.
    final class ScheduledConsentFormAllocationValidator {
        var rules: [any ScheduledConsentFormAllocationRule]

        init(rules: [any ScheduledConsentFormAllocationRule]) {
            self.rules = rules
        }

        func validate(_ item: ScheduledConsentFormAllocation) -> [String] {
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

        func requireValid(_ item: ScheduledConsentFormAllocation) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.displayLabel()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [ScheduledConsentFormAllocation]) -> [String: [String]] {
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

    static func defaultScheduledConsentFormAllocationValidator() -> ScheduledConsentFormAllocationValidator {
        return ScheduledConsentFormAllocationValidator(
            rules: [
                ScheduledConsentFormAllocationLabelLengthRule(maxLength: 64),
                ScheduledConsentFormAllocationOwnerIDLengthRule(maxLength: 16),
                ScheduledConsentFormAllocationRequiredCodeRule(
                    message: "scheduled consent form allocation needs this field"
                ),
                ScheduledConsentFormAllocationDurationMinutesRangeRule(min: 120, max: 120),
                ScheduledConsentFormAllocationSourceLengthRule(maxLength: 16),
            ]
        )
    }
}
