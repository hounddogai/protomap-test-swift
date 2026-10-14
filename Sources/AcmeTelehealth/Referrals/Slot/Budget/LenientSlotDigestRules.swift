import AcmePlatform
import Foundation

extension Referrals {
    /// A rule a lenient slot digest must pass. Check returns its problems, or none.
    protocol LenientSlotDigestRule {
        func check(_ item: LenientSlotDigest) -> [String]
    }

    final class LenientSlotDigestTitleLengthRule: LenientSlotDigestRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: LenientSlotDigest) -> [String] {
            let size = item.title.count
            if size > maxLength {
                return ["title is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class LenientSlotDigestGraceDaysRangeRule: LenientSlotDigestRule {
        var min: Int
        var max: Int

        init(min: Int, max: Int) {
            self.min = min
            self.max = max
        }

        func check(_ item: LenientSlotDigest) -> [String] {
            let value = item.graceDays
            if value < min || value > max {
                return ["grace days \(value) is outside \(min) to \(max)"]
            }
            return []
        }
    }

    final class LenientSlotDigestAttemptsRangeRule: LenientSlotDigestRule {
        var min: Int
        var max: Int

        init(min: Int, max: Int) {
            self.min = min
            self.max = max
        }

        func check(_ item: LenientSlotDigest) -> [String] {
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

    /// Runs every rule of a lenient slot digest.
    final class LenientSlotDigestValidator {
        var rules: [any LenientSlotDigestRule]

        init(rules: [any LenientSlotDigestRule]) {
            self.rules = rules
        }

        func validate(_ item: LenientSlotDigest) -> [String] {
            var problems: [String] = []
            for rule in rules {
                for problem in rule.check(item) {
                    problems.append(problem)
                }
            }
            return problems
        }

        func requireValid(_ item: LenientSlotDigest) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.displayLabel()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [LenientSlotDigest]) -> [String: [String]] {
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

    static func defaultLenientSlotDigestValidator() -> LenientSlotDigestValidator {
        return LenientSlotDigestValidator(
            rules: [
                LenientSlotDigestTitleLengthRule(maxLength: 86400),
                LenientSlotDigestGraceDaysRangeRule(min: 16, max: 16),
                LenientSlotDigestAttemptsRangeRule(min: 80, max: 3600),
            ]
        )
    }
}
