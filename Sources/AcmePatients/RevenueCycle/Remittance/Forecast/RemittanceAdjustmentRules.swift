import AcmePlatform
import Foundation

extension RevenueCycle {
    /// A rule a remittance adjustment must pass. Check returns its problems, or none.
    protocol RemittanceAdjustmentRule {
        func check(_ item: RemittanceAdjustment) -> [String]
    }

    final class RemittanceAdjustmentTagsLimitRule: RemittanceAdjustmentRule {
        var maxCount: Int
        var banned: [String]

        init(maxCount: Int, banned: [String]) {
            self.maxCount = maxCount
            self.banned = banned
        }

        func check(_ item: RemittanceAdjustment) -> [String] {
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

    final class RemittanceAdjustmentRateRangeRule: RemittanceAdjustmentRule {
        var min: Double
        var max: Double

        init(min: Double, max: Double) {
            self.min = min
            self.max = max
        }

        func check(_ item: RemittanceAdjustment) -> [String] {
            let value = item.rate
            var problems: [String] = []
            if value < min {
                problems.append("rate \(value) is below \(min)")
            }
            if value > max {
                problems.append("rate \(value) is above \(max)")
            }
            return problems
        }
    }

    final class RemittanceAdjustmentRequiredSegmentRule: RemittanceAdjustmentRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: RemittanceAdjustment) -> [String] {
            if item.segment.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class RemittanceAdjustmentSegmentLengthRule: RemittanceAdjustmentRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: RemittanceAdjustment) -> [String] {
            let size = item.segment.count
            if size > maxLength {
                return ["segment is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    /// Runs every rule of a remittance adjustment.
    final class RemittanceAdjustmentValidator {
        var rules: [any RemittanceAdjustmentRule]

        init(rules: [any RemittanceAdjustmentRule]) {
            self.rules = rules
        }

        func validate(_ item: RemittanceAdjustment) -> [String] {
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

        func requireValid(_ item: RemittanceAdjustment) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.displayLabel()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [RemittanceAdjustment]) -> [String: [String]] {
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

    static func defaultRemittanceAdjustmentValidator() -> RemittanceAdjustmentValidator {
        return RemittanceAdjustmentValidator(
            rules: [
                RemittanceAdjustmentTagsLimitRule(maxCount: 86400, banned: ["capped", "capped"]),
                RemittanceAdjustmentRateRangeRule(min: 1.6, max: 4189.3),
                RemittanceAdjustmentRequiredSegmentRule(message: "remittance adjustment needs a value"),
                RemittanceAdjustmentSegmentLengthRule(maxLength: 86400),
            ]
        )
    }
}
