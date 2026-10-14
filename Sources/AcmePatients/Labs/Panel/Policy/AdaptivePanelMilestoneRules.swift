import AcmePlatform
import Foundation

extension Labs {
    /// A rule a adaptive panel milestone must pass. Check returns its problems, or none.
    protocol AdaptivePanelMilestoneRule {
        func check(_ item: AdaptivePanelMilestone) -> [String]
    }

    final class AdaptivePanelMilestoneVisibleGuardRule: AdaptivePanelMilestoneRule {
        var limit: Int

        init(limit: Int) {
            self.limit = limit
        }

        func check(_ item: AdaptivePanelMilestone) -> [String] {
            if item.visible && (item.refills > limit) {
                return ["refills \(item.refills) exceeds \(limit) while visible"]
            }
            return []
        }
    }

    final class AdaptivePanelMilestoneEncounterIDLengthRule: AdaptivePanelMilestoneRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: AdaptivePanelMilestone) -> [String] {
            let size = item.encounterID.count
            if size > maxLength {
                return ["encounter id is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class AdaptivePanelMilestoneRequiredEncounterIDRule: AdaptivePanelMilestoneRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: AdaptivePanelMilestone) -> [String] {
            if item.encounterID.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class AdaptivePanelMilestoneRequiredNameRule: AdaptivePanelMilestoneRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: AdaptivePanelMilestone) -> [String] {
            if item.name.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    /// Runs every rule of a adaptive panel milestone.
    final class AdaptivePanelMilestoneValidator {
        var rules: [any AdaptivePanelMilestoneRule]

        init(rules: [any AdaptivePanelMilestoneRule]) {
            self.rules = rules
        }

        func validate(_ item: AdaptivePanelMilestone) -> [String] {
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

        func requireValid(_ item: AdaptivePanelMilestone) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.label()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [AdaptivePanelMilestone]) -> [String: [String]] {
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

    static func defaultAdaptivePanelMilestoneValidator() -> AdaptivePanelMilestoneValidator {
        return AdaptivePanelMilestoneValidator(
            rules: [
                AdaptivePanelMilestoneVisibleGuardRule(limit: 16),
                AdaptivePanelMilestoneEncounterIDLengthRule(maxLength: 16),
                AdaptivePanelMilestoneRequiredEncounterIDRule(message: "adaptive panel milestone needs an entry"),
                AdaptivePanelMilestoneRequiredNameRule(message: "adaptive panel milestone needs a value"),
            ]
        )
    }
}
