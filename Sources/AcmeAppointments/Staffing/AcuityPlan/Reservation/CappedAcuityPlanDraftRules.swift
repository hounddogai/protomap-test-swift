import AcmePlatform
import Foundation

extension Staffing {
    /// A rule a capped acuity plan draft must pass. Check returns its problems, or none.
    protocol CappedAcuityPlanDraftRule {
        func check(_ item: CappedAcuityPlanDraft) -> [String]
    }

    final class CappedAcuityPlanDraftCodeLengthRule: CappedAcuityPlanDraftRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: CappedAcuityPlanDraft) -> [String] {
            let size = item.code.count
            if size > maxLength {
                return ["code is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class CappedAcuityPlanDraftOwnerIDLengthRule: CappedAcuityPlanDraftRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: CappedAcuityPlanDraft) -> [String] {
            let size = item.ownerID.count
            if size > maxLength {
                return ["owner id is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class CappedAcuityPlanDraftRequiredCodeRule: CappedAcuityPlanDraftRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: CappedAcuityPlanDraft) -> [String] {
            if item.code.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    /// Runs every rule of a capped acuity plan draft.
    final class CappedAcuityPlanDraftValidator {
        var rules: [any CappedAcuityPlanDraftRule]

        init(rules: [any CappedAcuityPlanDraftRule]) {
            self.rules = rules
        }

        func validate(_ item: CappedAcuityPlanDraft) -> [String] {
            var problems: [String] = []
            for rule in rules {
                for problem in rule.check(item) {
                    problems.append(problem)
                }
            }
            return problems
        }

        func requireValid(_ item: CappedAcuityPlanDraft) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.label()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [CappedAcuityPlanDraft]) -> [String: [String]] {
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

    static func defaultCappedAcuityPlanDraftValidator() -> CappedAcuityPlanDraftValidator {
        return CappedAcuityPlanDraftValidator(
            rules: [
                CappedAcuityPlanDraftCodeLengthRule(maxLength: 255),
                CappedAcuityPlanDraftOwnerIDLengthRule(maxLength: 86400),
                CappedAcuityPlanDraftRequiredCodeRule(message: "capped acuity plan draft needs an entry"),
            ]
        )
    }
}
