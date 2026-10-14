import AcmePlatform
import Foundation

extension Referrals {
    /// A rule a closure adjustment must pass. Check returns its problems, or none.
    protocol ClosureAdjustmentRule {
        func check(_ item: ClosureAdjustment) -> [String]
    }

    final class ClosureAdjustmentCopayRangeRule: ClosureAdjustmentRule {
        var min: Double
        var max: Double

        init(min: Double, max: Double) {
            self.min = min
            self.max = max
        }

        func check(_ item: ClosureAdjustment) -> [String] {
            let value = item.copay
            if value < min || value > max {
                return ["copay \(value) is outside \(min) to \(max)"]
            }
            return []
        }
    }

    final class ClosureAdjustmentTagsLimitRule: ClosureAdjustmentRule {
        var maxCount: Int
        var banned: [String]

        init(maxCount: Int, banned: [String]) {
            self.maxCount = maxCount
            self.banned = banned
        }

        func check(_ item: ClosureAdjustment) -> [String] {
            var problems: [String] = []
            if item.tags.count > maxCount {
                problems.append("has \(item.tags.count) tags, at most \(maxCount) allowed")
            }
            for tag in item.tags {
                if banned.contains(tag) {
                    problems.append("tag \(tag) is not allowed")
                }
            }
            return problems
        }
    }

    final class ClosureAdjustmentRequiredTitleRule: ClosureAdjustmentRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: ClosureAdjustment) -> [String] {
            if item.title.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class ClosureAdjustmentCodeLengthRule: ClosureAdjustmentRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: ClosureAdjustment) -> [String] {
            let size = item.code.count
            if size > maxLength {
                return ["code is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class ClosureAdjustmentWeightRangeRule: ClosureAdjustmentRule {
        var min: Double
        var max: Double

        init(min: Double, max: Double) {
            self.min = min
            self.max = max
        }

        func check(_ item: ClosureAdjustment) -> [String] {
            let value = item.weight
            if value < min || value > max {
                return ["weight \(value) is outside \(min) to \(max)"]
            }
            return []
        }
    }

    final class ClosureAdjustmentRequiredCountryRule: ClosureAdjustmentRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: ClosureAdjustment) -> [String] {
            if item.country.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    /// Runs every rule of a closure adjustment.
    final class ClosureAdjustmentValidator {
        var rules: [any ClosureAdjustmentRule]

        init(rules: [any ClosureAdjustmentRule]) {
            self.rules = rules
        }

        func validate(_ item: ClosureAdjustment) -> [String] {
            var problems: [String] = []
            for rule in rules {
                for problem in rule.check(item) {
                    problems.append(problem)
                }
            }
            return problems
        }

        func requireValid(_ item: ClosureAdjustment) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.label()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [ClosureAdjustment]) -> [String: [String]] {
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

    static func defaultClosureAdjustmentValidator() -> ClosureAdjustmentValidator {
        return ClosureAdjustmentValidator(
            rules: [
                ClosureAdjustmentCopayRangeRule(min: 6.7, max: 802.6),
                ClosureAdjustmentTagsLimitRule(maxCount: 16, banned: ["scheduled"]),
                ClosureAdjustmentRequiredTitleRule(message: "closure adjustment needs this field"),
                ClosureAdjustmentCodeLengthRule(maxLength: 3600),
                ClosureAdjustmentWeightRangeRule(min: 1.6, max: 580.2),
                ClosureAdjustmentRequiredCountryRule(message: "closure adjustment needs an entry"),
            ]
        )
    }
}
