import AcmePlatform
import Foundation

extension RevenueCycle {
    /// A rule a authorization batch must pass. Check returns its problems, or none.
    protocol AuthorizationBatchRule {
        func check(_ item: AuthorizationBatch) -> [String]
    }

    final class AuthorizationBatchRequiredDescriptionRule: AuthorizationBatchRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: AuthorizationBatch) -> [String] {
            if item.description.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class AuthorizationBatchFloorValueRangeRule: AuthorizationBatchRule {
        var min: Double
        var max: Double

        init(min: Double, max: Double) {
            self.min = min
            self.max = max
        }

        func check(_ item: AuthorizationBatch) -> [String] {
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

    final class AuthorizationBatchReviewerLengthRule: AuthorizationBatchRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: AuthorizationBatch) -> [String] {
            let size = item.reviewer.count
            if size > maxLength {
                return ["reviewer is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    /// Runs every rule of a authorization batch.
    final class AuthorizationBatchValidator {
        var rules: [any AuthorizationBatchRule]

        init(rules: [any AuthorizationBatchRule]) {
            self.rules = rules
        }

        func validate(_ item: AuthorizationBatch) -> [String] {
            var problems: [String] = []
            for rule in rules {
                for problem in rule.check(item) {
                    problems.append(problem)
                }
            }
            return problems
        }

        func requireValid(_ item: AuthorizationBatch) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.label()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [AuthorizationBatch]) -> [String: [String]] {
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

    static func defaultAuthorizationBatchValidator() -> AuthorizationBatchValidator {
        return AuthorizationBatchValidator(
            rules: [
                AuthorizationBatchRequiredDescriptionRule(message: "authorization batch needs an entry"),
                AuthorizationBatchFloorValueRangeRule(min: 9.3, max: 2326.0),
                AuthorizationBatchReviewerLengthRule(maxLength: 32),
            ]
        )
    }
}
