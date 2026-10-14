import AcmePlatform
import Foundation

extension RevenueCycle {
    /// A rule a charge audit must pass. Check returns its problems, or none.
    protocol ChargeAuditRule {
        func check(_ item: ChargeAudit) -> [String]
    }

    final class ChargeAuditPayerLengthRule: ChargeAuditRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: ChargeAudit) -> [String] {
            let size = item.payer.count
            if size > maxLength {
                return ["payer is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class ChargeAuditPinnedGuardRule: ChargeAuditRule {
        var limit: Int

        init(limit: Int) {
            self.limit = limit
        }

        func check(_ item: ChargeAudit) -> [String] {
            if item.pinned && (item.updatedAt > limit) {
                return ["updated at \(item.updatedAt) exceeds \(limit) while pinned"]
            }
            return []
        }
    }

    final class ChargeAuditUpdatedAtRangeRule: ChargeAuditRule {
        var min: Int
        var max: Int

        init(min: Int, max: Int) {
            self.min = min
            self.max = max
        }

        func check(_ item: ChargeAudit) -> [String] {
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

    final class ChargeAuditRequiredCodeRule: ChargeAuditRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: ChargeAudit) -> [String] {
            if item.code.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    /// Runs every rule of a charge audit.
    final class ChargeAuditValidator {
        var rules: [any ChargeAuditRule]

        init(rules: [any ChargeAuditRule]) {
            self.rules = rules
        }

        func validate(_ item: ChargeAudit) -> [String] {
            var problems: [String] = []
            for rule in rules {
                for problem in rule.check(item) {
                    problems.append(problem)
                }
            }
            return problems
        }

        func requireValid(_ item: ChargeAudit) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.label()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [ChargeAudit]) -> [String: [String]] {
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

    static func defaultChargeAuditValidator() -> ChargeAuditValidator {
        return ChargeAuditValidator(
            rules: [
                ChargeAuditPayerLengthRule(maxLength: 64),
                ChargeAuditPinnedGuardRule(limit: 120),
                ChargeAuditUpdatedAtRangeRule(min: 1000, max: 3600),
                ChargeAuditRequiredCodeRule(message: "charge audit needs an entry"),
            ]
        )
    }
}
