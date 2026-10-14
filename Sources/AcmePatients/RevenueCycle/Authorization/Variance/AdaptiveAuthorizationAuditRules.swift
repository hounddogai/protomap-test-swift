import AcmePlatform
import Foundation

extension RevenueCycle {
    /// A rule a adaptive authorization audit must pass. Check returns its problems, or none.
    protocol AdaptiveAuthorizationAuditRule {
        func check(_ item: AdaptiveAuthorizationAudit) -> [String]
    }

    final class AdaptiveAuthorizationAuditStartsAtRangeRule: AdaptiveAuthorizationAuditRule {
        var min: Int
        var max: Int

        init(min: Int, max: Int) {
            self.min = min
            self.max = max
        }

        func check(_ item: AdaptiveAuthorizationAudit) -> [String] {
            let value = item.startsAt
            var problems: [String] = []
            if value < min {
                problems.append("starts at \(value) is below \(min)")
            }
            if value > max {
                problems.append("starts at \(value) is above \(max)")
            }
            return problems
        }
    }

    final class AdaptiveAuthorizationAuditRequiredTitleRule: AdaptiveAuthorizationAuditRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: AdaptiveAuthorizationAudit) -> [String] {
            if item.title.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class AdaptiveAuthorizationAuditCodeLengthRule: AdaptiveAuthorizationAuditRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: AdaptiveAuthorizationAudit) -> [String] {
            let size = item.code.count
            if size > maxLength {
                return ["code is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class AdaptiveAuthorizationAuditRequiredCodeRule: AdaptiveAuthorizationAuditRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: AdaptiveAuthorizationAudit) -> [String] {
            if item.code.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    /// Runs every rule of a adaptive authorization audit.
    final class AdaptiveAuthorizationAuditValidator {
        var rules: [any AdaptiveAuthorizationAuditRule]

        init(rules: [any AdaptiveAuthorizationAuditRule]) {
            self.rules = rules
        }

        func validate(_ item: AdaptiveAuthorizationAudit) -> [String] {
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

        func requireValid(_ item: AdaptiveAuthorizationAudit) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.label()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [AdaptiveAuthorizationAudit]) -> [String: [String]] {
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

    static func defaultAdaptiveAuthorizationAuditValidator() -> AdaptiveAuthorizationAuditValidator {
        return AdaptiveAuthorizationAuditValidator(
            rules: [
                AdaptiveAuthorizationAuditStartsAtRangeRule(min: 255, max: 3600),
                AdaptiveAuthorizationAuditRequiredTitleRule(message: "adaptive authorization audit needs an entry"),
                AdaptiveAuthorizationAuditCodeLengthRule(maxLength: 1000),
                AdaptiveAuthorizationAuditRequiredCodeRule(message: "adaptive authorization audit needs this field"),
            ]
        )
    }
}
