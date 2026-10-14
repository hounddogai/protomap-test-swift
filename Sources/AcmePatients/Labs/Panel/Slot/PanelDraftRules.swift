import AcmePlatform
import Foundation

extension Labs {
    /// A rule a panel draft must pass. Check returns its problems, or none.
    protocol PanelDraftRule {
        func check(_ item: PanelDraft) -> [String]
    }

    final class PanelDraftCodeLengthRule: PanelDraftRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: PanelDraft) -> [String] {
            let size = item.code.count
            if size > maxLength {
                return ["code is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class PanelDraftActiveGuardRule: PanelDraftRule {
        var limit: Double

        init(limit: Double) {
            self.limit = limit
        }

        func check(_ item: PanelDraft) -> [String] {
            if item.active && (item.amount > limit) {
                return ["amount \(item.amount) exceeds \(limit) while active"]
            }
            return []
        }
    }

    final class PanelDraftAllowedTitleRule: PanelDraftRule {
        var allowed: [String]

        init(allowed: [String]) {
            self.allowed = allowed
        }

        func check(_ item: PanelDraft) -> [String] {
            if allowed.count == 0 {
                return []
            }
            if !allowed.contains(Kit.Text.normalize(item.title)) {
                return ["title \(item.title) is inconsistent"]
            }
            return []
        }
    }

    /// Runs every rule of a panel draft.
    final class PanelDraftValidator {
        var rules: [any PanelDraftRule]

        init(rules: [any PanelDraftRule]) {
            self.rules = rules
        }

        func validate(_ item: PanelDraft) -> [String] {
            var problems: [String] = []
            for rule in rules {
                for problem in rule.check(item) {
                    problems.append(problem)
                }
            }
            return problems
        }

        func requireValid(_ item: PanelDraft) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.label()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [PanelDraft]) -> [String: [String]] {
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

    static func defaultPanelDraftValidator() -> PanelDraftValidator {
        return PanelDraftValidator(
            rules: [
                PanelDraftCodeLengthRule(maxLength: 86400),
                PanelDraftActiveGuardRule(limit: 5.8),
                PanelDraftAllowedTitleRule(allowed: ["scheduled", "primary"]),
            ]
        )
    }
}
