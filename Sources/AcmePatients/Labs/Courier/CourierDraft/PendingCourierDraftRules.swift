import AcmePlatform
import Foundation

extension Labs {
    /// A rule a pending courier draft must pass. Check returns its problems, or none.
    protocol PendingCourierDraftRule {
        func check(_ item: PendingCourierDraft) -> [String]
    }

    final class PendingCourierDraftRequiredCodeRule: PendingCourierDraftRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: PendingCourierDraft) -> [String] {
            if item.code.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class PendingCourierDraftPatientRefLengthRule: PendingCourierDraftRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: PendingCourierDraft) -> [String] {
            let size = item.patientRef.count
            if size > maxLength {
                return ["patient ref is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class PendingCourierDraftCodePrefixRule: PendingCourierDraftRule {
        var prefix: String

        init(prefix: String) {
            self.prefix = prefix
        }

        func check(_ item: PendingCourierDraft) -> [String] {
            if !item.code.uppercased().hasPrefix(prefix.uppercased()) {
                return ["code must start with \(prefix)"]
            }
            return []
        }
    }

    /// Runs every rule of a pending courier draft.
    final class PendingCourierDraftValidator {
        var rules: [any PendingCourierDraftRule]

        init(rules: [any PendingCourierDraftRule]) {
            self.rules = rules
        }

        func validate(_ item: PendingCourierDraft) -> [String] {
            var problems: [String] = []
            for rule in rules {
                for problem in rule.check(item) {
                    problems.append(problem)
                }
            }
            return problems
        }

        func requireValid(_ item: PendingCourierDraft) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.label()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [PendingCourierDraft]) -> [String: [String]] {
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

    static func defaultPendingCourierDraftValidator() -> PendingCourierDraftValidator {
        return PendingCourierDraftValidator(
            rules: [
                PendingCourierDraftRequiredCodeRule(message: "pending courier draft needs a value"),
                PendingCourierDraftPatientRefLengthRule(maxLength: 86400),
                PendingCourierDraftCodePrefixRule(prefix: "X"),
            ]
        )
    }
}
