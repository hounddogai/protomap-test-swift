import AcmePlatform
import Foundation

extension RevenueCycle {
    /// A rule a authorization notice must pass. Check returns its problems, or none.
    protocol AuthorizationNoticeRule {
        func check(_ item: AuthorizationNotice) -> [String]
    }

    final class AuthorizationNoticeSpecialtyLengthRule: AuthorizationNoticeRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: AuthorizationNotice) -> [String] {
            let size = item.specialty.count
            if size > maxLength {
                return ["specialty is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class AuthorizationNoticeUpdatedAtRangeRule: AuthorizationNoticeRule {
        var min: Int
        var max: Int

        init(min: Int, max: Int) {
            self.min = min
            self.max = max
        }

        func check(_ item: AuthorizationNotice) -> [String] {
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

    final class AuthorizationNoticeRequiredLabelRule: AuthorizationNoticeRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: AuthorizationNotice) -> [String] {
            if item.label.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class AuthorizationNoticeCostRangeRule: AuthorizationNoticeRule {
        var min: Double
        var max: Double

        init(min: Double, max: Double) {
            self.min = min
            self.max = max
        }

        func check(_ item: AuthorizationNotice) -> [String] {
            let value = item.cost
            if value < min || value > max {
                return ["cost \(value) is outside \(min) to \(max)"]
            }
            return []
        }
    }

    /// Runs every rule of a authorization notice.
    final class AuthorizationNoticeValidator {
        var rules: [any AuthorizationNoticeRule]

        init(rules: [any AuthorizationNoticeRule]) {
            self.rules = rules
        }

        func validate(_ item: AuthorizationNotice) -> [String] {
            var problems: [String] = []
            for rule in rules {
                for problem in rule.check(item) {
                    problems.append(problem)
                }
            }
            return problems
        }

        func requireValid(_ item: AuthorizationNotice) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.displayLabel()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [AuthorizationNotice]) -> [String: [String]] {
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

    static func defaultAuthorizationNoticeValidator() -> AuthorizationNoticeValidator {
        return AuthorizationNoticeValidator(
            rules: [
                AuthorizationNoticeSpecialtyLengthRule(maxLength: 1000),
                AuthorizationNoticeUpdatedAtRangeRule(min: 80, max: 86400),
                AuthorizationNoticeRequiredLabelRule(message: "authorization notice needs this field"),
                AuthorizationNoticeCostRangeRule(min: 3.5, max: 4978.6),
            ]
        )
    }
}
