import AcmePlatform
import Foundation

extension RevenueCycle {
    /// A rule a authorization rollup must pass. Check returns its problems, or none.
    protocol AuthorizationRollupRule {
        func check(_ item: AuthorizationRollup) -> [String]
    }

    final class AuthorizationRollupContactEmailLengthRule: AuthorizationRollupRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: AuthorizationRollup) -> [String] {
            let size = item.contactEmail.count
            if size > maxLength {
                return ["contact email is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class AuthorizationRollupVersionRangeRule: AuthorizationRollupRule {
        var min: Int
        var max: Int

        init(min: Int, max: Int) {
            self.min = min
            self.max = max
        }

        func check(_ item: AuthorizationRollup) -> [String] {
            let value = item.version
            if value < min || value > max {
                return ["version \(value) is outside \(min) to \(max)"]
            }
            return []
        }
    }

    final class AuthorizationRollupFloorValueRangeRule: AuthorizationRollupRule {
        var min: Double
        var max: Double

        init(min: Double, max: Double) {
            self.min = min
            self.max = max
        }

        func check(_ item: AuthorizationRollup) -> [String] {
            let value = item.floorValue
            var problems: [String] = []
            if value < min {
                problems.append("floor value \(value) is below \(min)")
            }
            if value > max {
                problems.append("floor value \(value) is above \(max)")
            }
            return problems
        }
    }

    /// Runs every rule of a authorization rollup.
    final class AuthorizationRollupValidator {
        var rules: [any AuthorizationRollupRule]

        init(rules: [any AuthorizationRollupRule]) {
            self.rules = rules
        }

        func validate(_ item: AuthorizationRollup) -> [String] {
            var problems: [String] = []
            for rule in rules {
                for problem in rule.check(item) {
                    problems.append(problem)
                }
            }
            return problems
        }

        func requireValid(_ item: AuthorizationRollup) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.label()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [AuthorizationRollup]) -> [String: [String]] {
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

    static func defaultAuthorizationRollupValidator() -> AuthorizationRollupValidator {
        return AuthorizationRollupValidator(
            rules: [
                AuthorizationRollupContactEmailLengthRule(maxLength: 64),
                AuthorizationRollupVersionRangeRule(min: 1000, max: 3600),
                AuthorizationRollupFloorValueRangeRule(min: 7.7, max: 2897.9),
            ]
        )
    }
}
