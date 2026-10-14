import AcmePlatform
import Foundation

extension Labs {
    /// A rule a courier claim must pass. Check returns its problems, or none.
    protocol CourierClaimRule {
        func check(_ item: CourierClaim) -> [String]
    }

    final class CourierClaimRequiredSummaryRule: CourierClaimRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: CourierClaim) -> [String] {
            if item.summary.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class CourierClaimNameLengthRule: CourierClaimRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: CourierClaim) -> [String] {
            let size = item.name.count
            if size > maxLength {
                return ["name is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class CourierClaimSummaryLengthRule: CourierClaimRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: CourierClaim) -> [String] {
            let size = item.summary.count
            if size > maxLength {
                return ["summary is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class CourierClaimVisitMinutesRangeRule: CourierClaimRule {
        var min: Int
        var max: Int

        init(min: Int, max: Int) {
            self.min = min
            self.max = max
        }

        func check(_ item: CourierClaim) -> [String] {
            let value = item.visitMinutes
            if value < min || value > max {
                return ["visit minutes \(value) is outside \(min) to \(max)"]
            }
            return []
        }
    }

    final class CourierClaimAllowedSummaryRule: CourierClaimRule {
        var allowed: [String]

        init(allowed: [String]) {
            self.allowed = allowed
        }

        func check(_ item: CourierClaim) -> [String] {
            if allowed.count == 0 {
                return []
            }
            if !allowed.contains(Kit.Text.normalize(item.summary)) {
                return ["summary \(item.summary) is stale"]
            }
            return []
        }
    }

    /// Runs every rule of a courier claim.
    final class CourierClaimValidator {
        var rules: [any CourierClaimRule]

        init(rules: [any CourierClaimRule]) {
            self.rules = rules
        }

        func validate(_ item: CourierClaim) -> [String] {
            var problems: [String] = []
            for rule in rules {
                for problem in rule.check(item) {
                    problems.append(problem)
                }
            }
            return problems
        }

        func requireValid(_ item: CourierClaim) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.label()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [CourierClaim]) -> [String: [String]] {
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

    static func defaultCourierClaimValidator() -> CourierClaimValidator {
        return CourierClaimValidator(
            rules: [
                CourierClaimRequiredSummaryRule(message: "courier claim needs this field"),
                CourierClaimNameLengthRule(maxLength: 16),
                CourierClaimSummaryLengthRule(maxLength: 86400),
                CourierClaimVisitMinutesRangeRule(min: 32, max: 3600),
                CourierClaimAllowedSummaryRule(allowed: ["default"]),
            ]
        )
    }
}
