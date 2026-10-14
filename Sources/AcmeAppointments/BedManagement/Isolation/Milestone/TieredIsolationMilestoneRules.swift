import AcmePlatform
import Foundation

extension BedManagement {
    /// A rule a tiered isolation milestone must pass. Check returns its problems, or none.
    protocol TieredIsolationMilestoneRule {
        func check(_ item: TieredIsolationMilestone) -> [String]
    }

    final class TieredIsolationMilestoneRequiredCodeRule: TieredIsolationMilestoneRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: TieredIsolationMilestone) -> [String] {
            if item.code.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class TieredIsolationMilestoneRegionLengthRule: TieredIsolationMilestoneRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: TieredIsolationMilestone) -> [String] {
            let size = item.region.count
            if size > maxLength {
                return ["region is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class TieredIsolationMilestoneAllowedNameRule: TieredIsolationMilestoneRule {
        var allowed: [String]

        init(allowed: [String]) {
            self.allowed = allowed
        }

        func check(_ item: TieredIsolationMilestone) -> [String] {
            if allowed.count == 0 {
                return []
            }
            if !allowed.contains(Kit.Text.normalize(item.name)) {
                return ["name \(item.name) is unknown"]
            }
            return []
        }
    }

    /// Runs every rule of a tiered isolation milestone.
    final class TieredIsolationMilestoneValidator {
        var rules: [any TieredIsolationMilestoneRule]

        init(rules: [any TieredIsolationMilestoneRule]) {
            self.rules = rules
        }

        func validate(_ item: TieredIsolationMilestone) -> [String] {
            var problems: [String] = []
            for rule in rules {
                for problem in rule.check(item) {
                    problems.append(problem)
                }
            }
            return problems
        }

        func requireValid(_ item: TieredIsolationMilestone) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.label()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [TieredIsolationMilestone]) -> [String: [String]] {
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

    static func defaultTieredIsolationMilestoneValidator() -> TieredIsolationMilestoneValidator {
        return TieredIsolationMilestoneValidator(
            rules: [
                TieredIsolationMilestoneRequiredCodeRule(message: "tiered isolation milestone needs a value"),
                TieredIsolationMilestoneRegionLengthRule(maxLength: 120),
                TieredIsolationMilestoneAllowedNameRule(allowed: ["batched"]),
            ]
        )
    }
}
