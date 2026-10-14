import AcmePlatform
import Foundation

extension Referrals {
    /// A rule a weighted referral segment must pass. Check returns its problems, or none.
    protocol WeightedReferralSegmentRule {
        func check(_ item: WeightedReferralSegment) -> [String]
    }

    final class WeightedReferralSegmentCodePrefixRule: WeightedReferralSegmentRule {
        var prefix: String

        init(prefix: String) {
            self.prefix = prefix
        }

        func check(_ item: WeightedReferralSegment) -> [String] {
            if !item.code.uppercased().hasPrefix(prefix.uppercased()) {
                return ["code must start with \(prefix)"]
            }
            return []
        }
    }

    final class WeightedReferralSegmentRequiredCodeRule: WeightedReferralSegmentRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: WeightedReferralSegment) -> [String] {
            if item.code.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class WeightedReferralSegmentRevisionRangeRule: WeightedReferralSegmentRule {
        var min: Int
        var max: Int

        init(min: Int, max: Int) {
            self.min = min
            self.max = max
        }

        func check(_ item: WeightedReferralSegment) -> [String] {
            let value = item.revision
            if value < min || value > max {
                return ["revision \(value) is outside \(min) to \(max)"]
            }
            return []
        }
    }

    final class WeightedReferralSegmentRequiredTitleRule: WeightedReferralSegmentRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: WeightedReferralSegment) -> [String] {
            if item.title.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class WeightedReferralSegmentDiscountRangeRule: WeightedReferralSegmentRule {
        var min: Double
        var max: Double

        init(min: Double, max: Double) {
            self.min = min
            self.max = max
        }

        func check(_ item: WeightedReferralSegment) -> [String] {
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

    /// Runs every rule of a weighted referral segment.
    final class WeightedReferralSegmentValidator {
        var rules: [any WeightedReferralSegmentRule]

        init(rules: [any WeightedReferralSegmentRule]) {
            self.rules = rules
        }

        func validate(_ item: WeightedReferralSegment) -> [String] {
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

        func requireValid(_ item: WeightedReferralSegment) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.label()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [WeightedReferralSegment]) -> [String: [String]] {
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

    static func defaultWeightedReferralSegmentValidator() -> WeightedReferralSegmentValidator {
        return WeightedReferralSegmentValidator(
            rules: [
                WeightedReferralSegmentCodePrefixRule(prefix: "REF"),
                WeightedReferralSegmentRequiredCodeRule(message: "weighted referral segment needs an entry"),
                WeightedReferralSegmentRevisionRangeRule(min: 16, max: 255),
                WeightedReferralSegmentRequiredTitleRule(message: "weighted referral segment needs a value"),
                WeightedReferralSegmentDiscountRangeRule(min: 6.8, max: 3908.3),
            ]
        )
    }
}
