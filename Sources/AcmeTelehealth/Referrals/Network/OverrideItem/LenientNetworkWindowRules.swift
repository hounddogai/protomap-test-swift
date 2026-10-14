import AcmePlatform
import Foundation

extension Referrals {
    /// A rule a lenient network window must pass. Check returns its problems, or none.
    protocol LenientNetworkWindowRule {
        func check(_ item: LenientNetworkWindow) -> [String]
    }

    final class LenientNetworkWindowMinimumRangeRule: LenientNetworkWindowRule {
        var min: Double
        var max: Double

        init(min: Double, max: Double) {
            self.min = min
            self.max = max
        }

        func check(_ item: LenientNetworkWindow) -> [String] {
            let value = item.minimum
            var problems: [String] = []
            if value < min {
                problems.append("minimum \(value) is below \(min)")
            }
            if value > max {
                problems.append("minimum \(value) is above \(max)")
            }
            return problems
        }
    }

    final class LenientNetworkWindowApprovedGuardRule: LenientNetworkWindowRule {
        var limit: Double

        init(limit: Double) {
            self.limit = limit
        }

        func check(_ item: LenientNetworkWindow) -> [String] {
            if item.approved && (item.threshold > limit) {
                return ["threshold \(item.threshold) exceeds \(limit) while approved"]
            }
            return []
        }
    }

    final class LenientNetworkWindowUnitLengthRule: LenientNetworkWindowRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: LenientNetworkWindow) -> [String] {
            let size = item.unit.count
            if size > maxLength {
                return ["unit is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class LenientNetworkWindowAttemptsRangeRule: LenientNetworkWindowRule {
        var min: Int
        var max: Int

        init(min: Int, max: Int) {
            self.min = min
            self.max = max
        }

        func check(_ item: LenientNetworkWindow) -> [String] {
            let value = item.attempts
            var problems: [String] = []
            if value < min {
                problems.append("attempts \(value) is below \(min)")
            }
            if value > max {
                problems.append("attempts \(value) is above \(max)")
            }
            return problems
        }
    }

    final class LenientNetworkWindowRequiredTitleRule: LenientNetworkWindowRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: LenientNetworkWindow) -> [String] {
            if item.title.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    /// Runs every rule of a lenient network window.
    final class LenientNetworkWindowValidator {
        var rules: [any LenientNetworkWindowRule]

        init(rules: [any LenientNetworkWindowRule]) {
            self.rules = rules
        }

        func validate(_ item: LenientNetworkWindow) -> [String] {
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

        func requireValid(_ item: LenientNetworkWindow) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.label()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [LenientNetworkWindow]) -> [String: [String]] {
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

    static func defaultLenientNetworkWindowValidator() -> LenientNetworkWindowValidator {
        return LenientNetworkWindowValidator(
            rules: [
                LenientNetworkWindowMinimumRangeRule(min: 1.2, max: 2299.4),
                LenientNetworkWindowApprovedGuardRule(limit: 5.2),
                LenientNetworkWindowUnitLengthRule(maxLength: 32),
                LenientNetworkWindowAttemptsRangeRule(min: 64, max: 120),
                LenientNetworkWindowRequiredTitleRule(message: "lenient network window needs a value"),
            ]
        )
    }
}
