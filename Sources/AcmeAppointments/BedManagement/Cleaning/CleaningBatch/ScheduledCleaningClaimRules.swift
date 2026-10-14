import AcmePlatform
import Foundation

extension BedManagement {
    /// A rule a scheduled cleaning claim must pass. Check returns its problems, or none.
    protocol ScheduledCleaningClaimRule {
        func check(_ item: ScheduledCleaningClaim) -> [String]
    }

    final class ScheduledCleaningClaimCodePrefixRule: ScheduledCleaningClaimRule {
        var prefix: String

        init(prefix: String) {
            self.prefix = prefix
        }

        func check(_ item: ScheduledCleaningClaim) -> [String] {
            if !item.code.uppercased().hasPrefix(prefix.uppercased()) {
                return ["code must start with \(prefix)"]
            }
            return []
        }
    }

    final class ScheduledCleaningClaimScoreRangeRule: ScheduledCleaningClaimRule {
        var min: Double
        var max: Double

        init(min: Double, max: Double) {
            self.min = min
            self.max = max
        }

        func check(_ item: ScheduledCleaningClaim) -> [String] {
            let value = item.score
            var problems: [String] = []
            if value < min {
                problems.append("score \(value) is below \(min)")
            }
            if value > max {
                problems.append("score \(value) is above \(max)")
            }
            return problems
        }
    }

    final class ScheduledCleaningClaimRequiredNameRule: ScheduledCleaningClaimRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: ScheduledCleaningClaim) -> [String] {
            if item.name.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class ScheduledCleaningClaimNameLengthRule: ScheduledCleaningClaimRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: ScheduledCleaningClaim) -> [String] {
            let size = item.name.count
            if size > maxLength {
                return ["name is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class ScheduledCleaningClaimCodeLengthRule: ScheduledCleaningClaimRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: ScheduledCleaningClaim) -> [String] {
            let size = item.code.count
            if size > maxLength {
                return ["code is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class ScheduledCleaningClaimRequiredCodeRule: ScheduledCleaningClaimRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: ScheduledCleaningClaim) -> [String] {
            if item.code.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    /// Runs every rule of a scheduled cleaning claim.
    final class ScheduledCleaningClaimValidator {
        var rules: [any ScheduledCleaningClaimRule]

        init(rules: [any ScheduledCleaningClaimRule]) {
            self.rules = rules
        }

        func validate(_ item: ScheduledCleaningClaim) -> [String] {
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

        func requireValid(_ item: ScheduledCleaningClaim) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.label()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [ScheduledCleaningClaim]) -> [String: [String]] {
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

    static func defaultScheduledCleaningClaimValidator() -> ScheduledCleaningClaimValidator {
        return ScheduledCleaningClaimValidator(
            rules: [
                ScheduledCleaningClaimCodePrefixRule(prefix: "ACM"),
                ScheduledCleaningClaimScoreRangeRule(min: 1.1, max: 172.3),
                ScheduledCleaningClaimRequiredNameRule(message: "scheduled cleaning claim needs this field"),
                ScheduledCleaningClaimNameLengthRule(maxLength: 3600),
                ScheduledCleaningClaimCodeLengthRule(maxLength: 3600),
                ScheduledCleaningClaimRequiredCodeRule(message: "scheduled cleaning claim needs a value"),
            ]
        )
    }
}
