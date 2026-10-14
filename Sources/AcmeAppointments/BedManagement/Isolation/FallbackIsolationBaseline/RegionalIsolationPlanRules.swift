import AcmePlatform
import Foundation

extension BedManagement {
    /// A rule a regional isolation plan must pass. Check returns its problems, or none.
    protocol RegionalIsolationPlanRule {
        func check(_ item: RegionalIsolationPlan) -> [String]
    }

    final class RegionalIsolationPlanCodePrefixRule: RegionalIsolationPlanRule {
        var prefix: String

        init(prefix: String) {
            self.prefix = prefix
        }

        func check(_ item: RegionalIsolationPlan) -> [String] {
            if !item.code.uppercased().hasPrefix(prefix.uppercased()) {
                return ["code must start with \(prefix)"]
            }
            return []
        }
    }

    final class RegionalIsolationPlanRequiredRegionRule: RegionalIsolationPlanRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: RegionalIsolationPlan) -> [String] {
            if item.region.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class RegionalIsolationPlanRegionLengthRule: RegionalIsolationPlanRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: RegionalIsolationPlan) -> [String] {
            let size = item.region.count
            if size > maxLength {
                return ["region is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class RegionalIsolationPlanCodeLengthRule: RegionalIsolationPlanRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: RegionalIsolationPlan) -> [String] {
            let size = item.code.count
            if size > maxLength {
                return ["code is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class RegionalIsolationPlanRequiredTitleRule: RegionalIsolationPlanRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: RegionalIsolationPlan) -> [String] {
            if item.title.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    /// Runs every rule of a regional isolation plan.
    final class RegionalIsolationPlanValidator {
        var rules: [any RegionalIsolationPlanRule]

        init(rules: [any RegionalIsolationPlanRule]) {
            self.rules = rules
        }

        func validate(_ item: RegionalIsolationPlan) -> [String] {
            var problems: [String] = []
            for rule in rules {
                for problem in rule.check(item) {
                    problems.append(problem)
                }
            }
            return problems
        }

        func requireValid(_ item: RegionalIsolationPlan) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.label()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [RegionalIsolationPlan]) -> [String: [String]] {
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

    static func defaultRegionalIsolationPlanValidator() -> RegionalIsolationPlanValidator {
        return RegionalIsolationPlanValidator(
            rules: [
                RegionalIsolationPlanCodePrefixRule(prefix: "REF"),
                RegionalIsolationPlanRequiredRegionRule(message: "regional isolation plan needs this field"),
                RegionalIsolationPlanRegionLengthRule(maxLength: 86400),
                RegionalIsolationPlanCodeLengthRule(maxLength: 32),
                RegionalIsolationPlanRequiredTitleRule(message: "regional isolation plan needs this field"),
            ]
        )
    }
}
