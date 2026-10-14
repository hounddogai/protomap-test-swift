import AcmePlatform
import Foundation

extension CareManagement {
    /// A rule a primary outreach plan must pass. Check returns its problems, or none.
    protocol PrimaryOutreachPlanRule {
        func check(_ item: PrimaryOutreachPlan) -> [String]
    }

    final class PrimaryOutreachPlanRequiredChannelRule: PrimaryOutreachPlanRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: PrimaryOutreachPlan) -> [String] {
            if item.channel.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class PrimaryOutreachPlanRegionLengthRule: PrimaryOutreachPlanRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: PrimaryOutreachPlan) -> [String] {
            let size = item.region.count
            if size > maxLength {
                return ["region is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class PrimaryOutreachPlanRequiredRegionRule: PrimaryOutreachPlanRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: PrimaryOutreachPlan) -> [String] {
            if item.region.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class PrimaryOutreachPlanCodeLengthRule: PrimaryOutreachPlanRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: PrimaryOutreachPlan) -> [String] {
            let size = item.code.count
            if size > maxLength {
                return ["code is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class PrimaryOutreachPlanRequiredCodeRule: PrimaryOutreachPlanRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: PrimaryOutreachPlan) -> [String] {
            if item.code.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    /// Runs every rule of a primary outreach plan.
    final class PrimaryOutreachPlanValidator {
        var rules: [any PrimaryOutreachPlanRule]

        init(rules: [any PrimaryOutreachPlanRule]) {
            self.rules = rules
        }

        func validate(_ item: PrimaryOutreachPlan) -> [String] {
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

        func requireValid(_ item: PrimaryOutreachPlan) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.label()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [PrimaryOutreachPlan]) -> [String: [String]] {
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

    static func defaultPrimaryOutreachPlanValidator() -> PrimaryOutreachPlanValidator {
        return PrimaryOutreachPlanValidator(
            rules: [
                PrimaryOutreachPlanRequiredChannelRule(message: "primary outreach plan needs this field"),
                PrimaryOutreachPlanRegionLengthRule(maxLength: 32),
                PrimaryOutreachPlanRequiredRegionRule(message: "primary outreach plan needs an entry"),
                PrimaryOutreachPlanCodeLengthRule(maxLength: 80),
                PrimaryOutreachPlanRequiredCodeRule(message: "primary outreach plan needs a value"),
            ]
        )
    }
}
