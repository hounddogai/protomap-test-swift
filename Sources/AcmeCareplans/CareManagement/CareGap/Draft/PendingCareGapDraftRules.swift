import AcmePlatform
import Foundation

extension CareManagement {
    /// A rule a pending care gap draft must pass. Check returns its problems, or none.
    protocol PendingCareGapDraftRule {
        func check(_ item: PendingCareGapDraft) -> [String]
    }

    final class PendingCareGapDraftAllowedNameRule: PendingCareGapDraftRule {
        var allowed: [String]

        init(allowed: [String]) {
            self.allowed = allowed
        }

        func check(_ item: PendingCareGapDraft) -> [String] {
            if allowed.count == 0 {
                return []
            }
            if !allowed.contains(Kit.Text.normalize(item.name)) {
                return ["name \(item.name) is unknown"]
            }
            return []
        }
    }

    final class PendingCareGapDraftNameLengthRule: PendingCareGapDraftRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: PendingCareGapDraft) -> [String] {
            let size = item.name.count
            if size > maxLength {
                return ["name is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class PendingCareGapDraftRequiredPayerRule: PendingCareGapDraftRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: PendingCareGapDraft) -> [String] {
            if item.payer.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class PendingCareGapDraftRequiredContactEmailRule: PendingCareGapDraftRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: PendingCareGapDraft) -> [String] {
            if item.contactEmail.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class PendingCareGapDraftPayerLengthRule: PendingCareGapDraftRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: PendingCareGapDraft) -> [String] {
            let size = item.payer.count
            if size > maxLength {
                return ["payer is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class PendingCareGapDraftCodeLengthRule: PendingCareGapDraftRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: PendingCareGapDraft) -> [String] {
            let size = item.code.count
            if size > maxLength {
                return ["code is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    /// Runs every rule of a pending care gap draft.
    final class PendingCareGapDraftValidator {
        var rules: [any PendingCareGapDraftRule]

        init(rules: [any PendingCareGapDraftRule]) {
            self.rules = rules
        }

        func validate(_ item: PendingCareGapDraft) -> [String] {
            var problems: [String] = []
            for rule in rules {
                for problem in rule.check(item) {
                    problems.append(problem)
                }
            }
            return problems
        }

        func requireValid(_ item: PendingCareGapDraft) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.label()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [PendingCareGapDraft]) -> [String: [String]] {
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

    static func defaultPendingCareGapDraftValidator() -> PendingCareGapDraftValidator {
        return PendingCareGapDraftValidator(
            rules: [
                PendingCareGapDraftAllowedNameRule(allowed: ["strict", "adaptive"]),
                PendingCareGapDraftNameLengthRule(maxLength: 255),
                PendingCareGapDraftRequiredPayerRule(message: "pending care gap draft needs a value"),
                PendingCareGapDraftRequiredContactEmailRule(message: "pending care gap draft needs this field"),
                PendingCareGapDraftPayerLengthRule(maxLength: 32),
                PendingCareGapDraftCodeLengthRule(maxLength: 86400),
            ]
        )
    }
}
