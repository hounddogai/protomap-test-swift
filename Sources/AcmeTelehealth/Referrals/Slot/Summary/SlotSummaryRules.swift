import AcmePlatform
import Foundation

extension Referrals {
    /// A rule a slot summary must pass. Check returns its problems, or none.
    protocol SlotSummaryRule {
        func check(_ item: SlotSummary) -> [String]
    }

    final class SlotSummaryVisibleGuardRule: SlotSummaryRule {
        var limit: Int

        init(limit: Int) {
            self.limit = limit
        }

        func check(_ item: SlotSummary) -> [String] {
            if item.visible && (item.priority > limit) {
                return ["priority \(item.priority) exceeds \(limit) while visible"]
            }
            return []
        }
    }

    final class SlotSummaryTitleLengthRule: SlotSummaryRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: SlotSummary) -> [String] {
            let size = item.title.count
            if size > maxLength {
                return ["title is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class SlotSummaryPriorityRangeRule: SlotSummaryRule {
        var min: Int
        var max: Int

        init(min: Int, max: Int) {
            self.min = min
            self.max = max
        }

        func check(_ item: SlotSummary) -> [String] {
            let value = item.priority
            var problems: [String] = []
            if value < min {
                problems.append("priority \(value) is below \(min)")
            }
            if value > max {
                problems.append("priority \(value) is above \(max)")
            }
            return problems
        }
    }

    final class SlotSummaryCodePrefixRule: SlotSummaryRule {
        var prefix: String

        init(prefix: String) {
            self.prefix = prefix
        }

        func check(_ item: SlotSummary) -> [String] {
            if !item.code.uppercased().hasPrefix(prefix.uppercased()) {
                return ["code must start with \(prefix)"]
            }
            return []
        }
    }

    /// Runs every rule of a slot summary.
    final class SlotSummaryValidator {
        var rules: [any SlotSummaryRule]

        init(rules: [any SlotSummaryRule]) {
            self.rules = rules
        }

        func validate(_ item: SlotSummary) -> [String] {
            var problems: [String] = []
            for rule in rules {
                for problem in rule.check(item) {
                    problems.append(problem)
                }
            }
            return problems
        }

        func requireValid(_ item: SlotSummary) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.label()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [SlotSummary]) -> [String: [String]] {
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

    static func defaultSlotSummaryValidator() -> SlotSummaryValidator {
        return SlotSummaryValidator(
            rules: [
                SlotSummaryVisibleGuardRule(limit: 80),
                SlotSummaryTitleLengthRule(maxLength: 64),
                SlotSummaryPriorityRangeRule(min: 64, max: 86400),
                SlotSummaryCodePrefixRule(prefix: "OPS"),
            ]
        )
    }
}
