import AcmePlatform
import Foundation

extension Consent {
    /// A rule a scheduled consent form draft must pass. Check returns its problems, or none.
    protocol ScheduledConsentFormDraftRule {
        func check(_ item: ScheduledConsentFormDraft) -> [String]
    }

    final class ScheduledConsentFormDraftEndsAtRangeRule: ScheduledConsentFormDraftRule {
        var min: Int
        var max: Int

        init(min: Int, max: Int) {
            self.min = min
            self.max = max
        }

        func check(_ item: ScheduledConsentFormDraft) -> [String] {
            let value = item.endsAt
            var problems: [String] = []
            if value < min {
                problems.append("ends at \(value) is below \(min)")
            }
            if value > max {
                problems.append("ends at \(value) is above \(max)")
            }
            return problems
        }
    }

    final class ScheduledConsentFormDraftCodeLengthRule: ScheduledConsentFormDraftRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: ScheduledConsentFormDraft) -> [String] {
            let size = item.code.count
            if size > maxLength {
                return ["code is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class ScheduledConsentFormDraftRateRangeRule: ScheduledConsentFormDraftRule {
        var min: Double
        var max: Double

        init(min: Double, max: Double) {
            self.min = min
            self.max = max
        }

        func check(_ item: ScheduledConsentFormDraft) -> [String] {
            let value = item.rate
            var problems: [String] = []
            if value < min {
                problems.append("rate \(value) is below \(min)")
            }
            if value > max {
                problems.append("rate \(value) is above \(max)")
            }
            return problems
        }
    }

    final class ScheduledConsentFormDraftRequiredCodeRule: ScheduledConsentFormDraftRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: ScheduledConsentFormDraft) -> [String] {
            if item.code.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class ScheduledConsentFormDraftRequiredChecksumRule: ScheduledConsentFormDraftRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: ScheduledConsentFormDraft) -> [String] {
            if item.checksum.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    /// Runs every rule of a scheduled consent form draft.
    final class ScheduledConsentFormDraftValidator {
        var rules: [any ScheduledConsentFormDraftRule]

        init(rules: [any ScheduledConsentFormDraftRule]) {
            self.rules = rules
        }

        func validate(_ item: ScheduledConsentFormDraft) -> [String] {
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

        func requireValid(_ item: ScheduledConsentFormDraft) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.label()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [ScheduledConsentFormDraft]) -> [String: [String]] {
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

    static func defaultScheduledConsentFormDraftValidator() -> ScheduledConsentFormDraftValidator {
        return ScheduledConsentFormDraftValidator(
            rules: [
                ScheduledConsentFormDraftEndsAtRangeRule(min: 3600, max: 86400),
                ScheduledConsentFormDraftCodeLengthRule(maxLength: 16),
                ScheduledConsentFormDraftRateRangeRule(min: 6.2, max: 4826.2),
                ScheduledConsentFormDraftRequiredCodeRule(message: "scheduled consent form draft needs this field"),
                ScheduledConsentFormDraftRequiredChecksumRule(
                    message: "scheduled consent form draft needs this field"
                ),
            ]
        )
    }
}
