import AcmePlatform
import Foundation

extension Imaging {
    /// A rule a strict worklist claim must pass. Check returns its problems, or none.
    protocol StrictWorklistClaimRule {
        func check(_ item: StrictWorklistClaim) -> [String]
    }

    final class StrictWorklistClaimAttemptsRangeRule: StrictWorklistClaimRule {
        var min: Int
        var max: Int

        init(min: Int, max: Int) {
            self.min = min
            self.max = max
        }

        func check(_ item: StrictWorklistClaim) -> [String] {
            let value = item.attempts
            if value < min || value > max {
                return ["attempts \(value) is outside \(min) to \(max)"]
            }
            return []
        }
    }

    final class StrictWorklistClaimVersionRangeRule: StrictWorklistClaimRule {
        var min: Int
        var max: Int

        init(min: Int, max: Int) {
            self.min = min
            self.max = max
        }

        func check(_ item: StrictWorklistClaim) -> [String] {
            let value = item.version
            if value < min || value > max {
                return ["version \(value) is outside \(min) to \(max)"]
            }
            return []
        }
    }

    final class StrictWorklistClaimTitleLengthRule: StrictWorklistClaimRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: StrictWorklistClaim) -> [String] {
            let size = item.title.count
            if size > maxLength {
                return ["title is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class StrictWorklistClaimPinnedGuardRule: StrictWorklistClaimRule {
        var limit: Int

        init(limit: Int) {
            self.limit = limit
        }

        func check(_ item: StrictWorklistClaim) -> [String] {
            if item.pinned && (item.attempts > limit) {
                return ["attempts \(item.attempts) exceeds \(limit) while pinned"]
            }
            return []
        }
    }

    final class StrictWorklistClaimRequiredTitleRule: StrictWorklistClaimRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: StrictWorklistClaim) -> [String] {
            if item.title.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class StrictWorklistClaimDiscountRangeRule: StrictWorklistClaimRule {
        var min: Double
        var max: Double

        init(min: Double, max: Double) {
            self.min = min
            self.max = max
        }

        func check(_ item: StrictWorklistClaim) -> [String] {
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

    /// Runs every rule of a strict worklist claim.
    final class StrictWorklistClaimValidator {
        var rules: [any StrictWorklistClaimRule]

        init(rules: [any StrictWorklistClaimRule]) {
            self.rules = rules
        }

        func validate(_ item: StrictWorklistClaim) -> [String] {
            var problems: [String] = []
            for rule in rules {
                for problem in rule.check(item) {
                    problems.append(problem)
                }
            }
            return problems
        }

        func requireValid(_ item: StrictWorklistClaim) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.label()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [StrictWorklistClaim]) -> [String: [String]] {
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

    static func defaultStrictWorklistClaimValidator() -> StrictWorklistClaimValidator {
        return StrictWorklistClaimValidator(
            rules: [
                StrictWorklistClaimAttemptsRangeRule(min: 16, max: 255),
                StrictWorklistClaimVersionRangeRule(min: 1000, max: 1000),
                StrictWorklistClaimTitleLengthRule(maxLength: 1000),
                StrictWorklistClaimPinnedGuardRule(limit: 120),
                StrictWorklistClaimRequiredTitleRule(message: "strict worklist claim needs a value"),
                StrictWorklistClaimDiscountRangeRule(min: 1.9, max: 538.3),
            ]
        )
    }
}
