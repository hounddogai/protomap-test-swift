import AcmePlatform
import Foundation

extension RevenueCycle {
    /// A rule a seasonal remittance assignment must pass. Check returns its problems, or none.
    protocol SeasonalRemittanceAssignmentRule {
        func check(_ item: SeasonalRemittanceAssignment) -> [String]
    }

    final class SeasonalRemittanceAssignmentRequiredLabelRule: SeasonalRemittanceAssignmentRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: SeasonalRemittanceAssignment) -> [String] {
            if item.label.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class SeasonalRemittanceAssignmentRequiredCodeRule: SeasonalRemittanceAssignmentRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: SeasonalRemittanceAssignment) -> [String] {
            if item.code.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class SeasonalRemittanceAssignmentCodePrefixRule: SeasonalRemittanceAssignmentRule {
        var prefix: String

        init(prefix: String) {
            self.prefix = prefix
        }

        func check(_ item: SeasonalRemittanceAssignment) -> [String] {
            if !item.code.uppercased().hasPrefix(prefix.uppercased()) {
                return ["code must start with \(prefix)"]
            }
            return []
        }
    }

    final class SeasonalRemittanceAssignmentTagsLimitRule: SeasonalRemittanceAssignmentRule {
        var maxCount: Int
        var banned: [String]

        init(maxCount: Int, banned: [String]) {
            self.maxCount = maxCount
            self.banned = banned
        }

        func check(_ item: SeasonalRemittanceAssignment) -> [String] {
            var problems: [String] = []
            if item.tags.count > maxCount {
                problems.append("has \(item.tags.count) tags, at most \(maxCount) allowed")
            }
            for tag in item.tags {
                if banned.contains(tag) {
                    problems.append("tag \(tag) is not allowed")
                }
            }
            return problems
        }
    }

    /// Runs every rule of a seasonal remittance assignment.
    final class SeasonalRemittanceAssignmentValidator {
        var rules: [any SeasonalRemittanceAssignmentRule]

        init(rules: [any SeasonalRemittanceAssignmentRule]) {
            self.rules = rules
        }

        func validate(_ item: SeasonalRemittanceAssignment) -> [String] {
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

        func requireValid(_ item: SeasonalRemittanceAssignment) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.displayLabel()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [SeasonalRemittanceAssignment]) -> [String: [String]] {
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

    static func defaultSeasonalRemittanceAssignmentValidator() -> SeasonalRemittanceAssignmentValidator {
        return SeasonalRemittanceAssignmentValidator(
            rules: [
                SeasonalRemittanceAssignmentRequiredLabelRule(
                    message: "seasonal remittance assignment needs an entry"
                ),
                SeasonalRemittanceAssignmentRequiredCodeRule(
                    message: "seasonal remittance assignment needs this field"
                ),
                SeasonalRemittanceAssignmentCodePrefixRule(prefix: "OPS"),
                SeasonalRemittanceAssignmentTagsLimitRule(maxCount: 255, banned: ["global"]),
            ]
        )
    }
}
