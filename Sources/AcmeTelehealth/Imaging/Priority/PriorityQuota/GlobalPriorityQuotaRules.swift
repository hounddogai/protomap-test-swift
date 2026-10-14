import AcmePlatform
import Foundation

extension Imaging {
    /// A rule a global priority quota must pass. Check returns its problems, or none.
    protocol GlobalPriorityQuotaRule {
        func check(_ item: GlobalPriorityQuota) -> [String]
    }

    final class GlobalPriorityQuotaEncounterIDLengthRule: GlobalPriorityQuotaRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: GlobalPriorityQuota) -> [String] {
            let size = item.encounterID.count
            if size > maxLength {
                return ["encounter id is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class GlobalPriorityQuotaUpdatedAtRangeRule: GlobalPriorityQuotaRule {
        var min: Int
        var max: Int

        init(min: Int, max: Int) {
            self.min = min
            self.max = max
        }

        func check(_ item: GlobalPriorityQuota) -> [String] {
            let value = item.updatedAt
            var problems: [String] = []
            if value < min {
                problems.append("updated at \(value) is below \(min)")
            }
            if value > max {
                problems.append("updated at \(value) is above \(max)")
            }
            return problems
        }
    }

    final class GlobalPriorityQuotaAllowedCodeRule: GlobalPriorityQuotaRule {
        var allowed: [String]

        init(allowed: [String]) {
            self.allowed = allowed
        }

        func check(_ item: GlobalPriorityQuota) -> [String] {
            if allowed.count == 0 {
                return []
            }
            if !allowed.contains(Kit.Text.normalize(item.code)) {
                return ["code \(item.code) is blocked"]
            }
            return []
        }
    }

    final class GlobalPriorityQuotaRequiredLabelRule: GlobalPriorityQuotaRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: GlobalPriorityQuota) -> [String] {
            if item.label.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    /// Runs every rule of a global priority quota.
    final class GlobalPriorityQuotaValidator {
        var rules: [any GlobalPriorityQuotaRule]

        init(rules: [any GlobalPriorityQuotaRule]) {
            self.rules = rules
        }

        func validate(_ item: GlobalPriorityQuota) -> [String] {
            var problems: [String] = []
            for rule in rules {
                for problem in rule.check(item) {
                    problems.append(problem)
                }
            }
            return problems
        }

        func requireValid(_ item: GlobalPriorityQuota) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.displayLabel()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [GlobalPriorityQuota]) -> [String: [String]] {
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

    static func defaultGlobalPriorityQuotaValidator() -> GlobalPriorityQuotaValidator {
        return GlobalPriorityQuotaValidator(
            rules: [
                GlobalPriorityQuotaEncounterIDLengthRule(maxLength: 1000),
                GlobalPriorityQuotaUpdatedAtRangeRule(min: 80, max: 1000),
                GlobalPriorityQuotaAllowedCodeRule(allowed: ["default", "weighted", "capped"]),
                GlobalPriorityQuotaRequiredLabelRule(message: "global priority quota needs a value"),
            ]
        )
    }
}
