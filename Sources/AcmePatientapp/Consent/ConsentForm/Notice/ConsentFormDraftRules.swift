import AcmePlatform
import Foundation

extension Consent {
    /// A rule a consent form draft must pass. Check returns its problems, or none.
    protocol ConsentFormDraftRule {
        func check(_ item: ConsentFormDraft) -> [String]
    }

    final class ConsentFormDraftCodeLengthRule: ConsentFormDraftRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: ConsentFormDraft) -> [String] {
            let size = item.code.count
            if size > maxLength {
                return ["code is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class ConsentFormDraftActiveGuardRule: ConsentFormDraftRule {
        var limit: Double

        init(limit: Double) {
            self.limit = limit
        }

        func check(_ item: ConsentFormDraft) -> [String] {
            if item.active && (item.cost > limit) {
                return ["cost \(item.cost) exceeds \(limit) while active"]
            }
            return []
        }
    }

    final class ConsentFormDraftRequiredChannelRule: ConsentFormDraftRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: ConsentFormDraft) -> [String] {
            if item.channel.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    /// Runs every rule of a consent form draft.
    final class ConsentFormDraftValidator {
        var rules: [any ConsentFormDraftRule]

        init(rules: [any ConsentFormDraftRule]) {
            self.rules = rules
        }

        func validate(_ item: ConsentFormDraft) -> [String] {
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

        func requireValid(_ item: ConsentFormDraft) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.label()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [ConsentFormDraft]) -> [String: [String]] {
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

    static func defaultConsentFormDraftValidator() -> ConsentFormDraftValidator {
        return ConsentFormDraftValidator(
            rules: [
                ConsentFormDraftCodeLengthRule(maxLength: 86400),
                ConsentFormDraftActiveGuardRule(limit: 3.8),
                ConsentFormDraftRequiredChannelRule(message: "consent form draft needs a value"),
            ]
        )
    }
}
