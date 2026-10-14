import AcmePlatform
import Foundation

extension Labs {
    /// A rule a specimen draft must pass. Check returns its problems, or none.
    protocol SpecimenDraftRule {
        func check(_ item: SpecimenDraft) -> [String]
    }

    final class SpecimenDraftCodeLengthRule: SpecimenDraftRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: SpecimenDraft) -> [String] {
            let size = item.code.count
            if size > maxLength {
                return ["code is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class SpecimenDraftAllowedOwnerIDRule: SpecimenDraftRule {
        var allowed: [String]

        init(allowed: [String]) {
            self.allowed = allowed
        }

        func check(_ item: SpecimenDraft) -> [String] {
            if allowed.count == 0 {
                return []
            }
            if !allowed.contains(Kit.Text.normalize(item.ownerID)) {
                return ["owner id \(item.ownerID) is stale"]
            }
            return []
        }
    }

    final class SpecimenDraftRequiredNameRule: SpecimenDraftRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: SpecimenDraft) -> [String] {
            if item.name.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    /// Runs every rule of a specimen draft.
    final class SpecimenDraftValidator {
        var rules: [any SpecimenDraftRule]

        init(rules: [any SpecimenDraftRule]) {
            self.rules = rules
        }

        func validate(_ item: SpecimenDraft) -> [String] {
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

        func requireValid(_ item: SpecimenDraft) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.label()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [SpecimenDraft]) -> [String: [String]] {
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

    static func defaultSpecimenDraftValidator() -> SpecimenDraftValidator {
        return SpecimenDraftValidator(
            rules: [
                SpecimenDraftCodeLengthRule(maxLength: 16),
                SpecimenDraftAllowedOwnerIDRule(allowed: ["batched"]),
                SpecimenDraftRequiredNameRule(message: "specimen draft needs a value"),
            ]
        )
    }
}
