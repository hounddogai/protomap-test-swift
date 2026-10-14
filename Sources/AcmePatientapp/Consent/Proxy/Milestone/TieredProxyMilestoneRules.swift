import AcmePlatform
import Foundation

extension Consent {
    /// A rule a tiered proxy milestone must pass. Check returns its problems, or none.
    protocol TieredProxyMilestoneRule {
        func check(_ item: TieredProxyMilestone) -> [String]
    }

    final class TieredProxyMilestoneOwnerIDLengthRule: TieredProxyMilestoneRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: TieredProxyMilestone) -> [String] {
            let size = item.ownerID.count
            if size > maxLength {
                return ["owner id is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class TieredProxyMilestoneNameLengthRule: TieredProxyMilestoneRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: TieredProxyMilestone) -> [String] {
            let size = item.name.count
            if size > maxLength {
                return ["name is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class TieredProxyMilestoneCodeLengthRule: TieredProxyMilestoneRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: TieredProxyMilestone) -> [String] {
            let size = item.code.count
            if size > maxLength {
                return ["code is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class TieredProxyMilestoneRequiredOwnerIDRule: TieredProxyMilestoneRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: TieredProxyMilestone) -> [String] {
            if item.ownerID.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    /// Runs every rule of a tiered proxy milestone.
    final class TieredProxyMilestoneValidator {
        var rules: [any TieredProxyMilestoneRule]

        init(rules: [any TieredProxyMilestoneRule]) {
            self.rules = rules
        }

        func validate(_ item: TieredProxyMilestone) -> [String] {
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

        func requireValid(_ item: TieredProxyMilestone) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.label()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [TieredProxyMilestone]) -> [String: [String]] {
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

    static func defaultTieredProxyMilestoneValidator() -> TieredProxyMilestoneValidator {
        return TieredProxyMilestoneValidator(
            rules: [
                TieredProxyMilestoneOwnerIDLengthRule(maxLength: 16),
                TieredProxyMilestoneNameLengthRule(maxLength: 86400),
                TieredProxyMilestoneCodeLengthRule(maxLength: 86400),
                TieredProxyMilestoneRequiredOwnerIDRule(message: "tiered proxy milestone needs an entry"),
            ]
        )
    }
}
