import AcmePlatform
import Foundation

extension RevenueCycle {
    /// A rule a authorization record must pass. Check returns its problems, or none.
    protocol AuthorizationRecordRule {
        func check(_ item: AuthorizationRecord) -> [String]
    }

    final class AuthorizationRecordDiscountRangeRule: AuthorizationRecordRule {
        var min: Double
        var max: Double

        init(min: Double, max: Double) {
            self.min = min
            self.max = max
        }

        func check(_ item: AuthorizationRecord) -> [String] {
            let value = item.discount
            var problems: [String] = []
            if value < min {
                problems.append("discount \(value) is below \(min)")
            }
            if value > max {
                problems.append("discount \(value) is above \(max)")
            }
            return problems
        }
    }

    final class AuthorizationRecordRequiredCodeRule: AuthorizationRecordRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: AuthorizationRecord) -> [String] {
            if item.code.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class AuthorizationRecordCodePrefixRule: AuthorizationRecordRule {
        var prefix: String

        init(prefix: String) {
            self.prefix = prefix
        }

        func check(_ item: AuthorizationRecord) -> [String] {
            if !item.code.uppercased().hasPrefix(prefix.uppercased()) {
                return ["code must start with \(prefix)"]
            }
            return []
        }
    }

    final class AuthorizationRecordCostRangeRule: AuthorizationRecordRule {
        var min: Double
        var max: Double

        init(min: Double, max: Double) {
            self.min = min
            self.max = max
        }

        func check(_ item: AuthorizationRecord) -> [String] {
            let value = item.cost
            var problems: [String] = []
            if value < min {
                problems.append("cost \(value) is below \(min)")
            }
            if value > max {
                problems.append("cost \(value) is above \(max)")
            }
            return problems
        }
    }

    /// Runs every rule of a authorization record.
    final class AuthorizationRecordValidator {
        var rules: [any AuthorizationRecordRule]

        init(rules: [any AuthorizationRecordRule]) {
            self.rules = rules
        }

        func validate(_ item: AuthorizationRecord) -> [String] {
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

        func requireValid(_ item: AuthorizationRecord) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.label()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [AuthorizationRecord]) -> [String: [String]] {
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

    static func defaultAuthorizationRecordValidator() -> AuthorizationRecordValidator {
        return AuthorizationRecordValidator(
            rules: [
                AuthorizationRecordDiscountRangeRule(min: 6.3, max: 872.3),
                AuthorizationRecordRequiredCodeRule(message: "authorization record needs a value"),
                AuthorizationRecordCodePrefixRule(prefix: "REF"),
                AuthorizationRecordCostRangeRule(min: 1.0, max: 3293.1),
            ]
        )
    }
}
