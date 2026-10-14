import AcmePlatform
import Foundation

extension Referrals {
    /// A rule a slot baseline must pass. Check returns its problems, or none.
    protocol SlotBaselineRule {
        func check(_ item: SlotBaseline) -> [String]
    }

    final class SlotBaselineRequiredLocaleRule: SlotBaselineRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: SlotBaseline) -> [String] {
            if item.locale.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class SlotBaselineLocaleLengthRule: SlotBaselineRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: SlotBaseline) -> [String] {
            let size = item.locale.count
            if size > maxLength {
                return ["locale is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class SlotBaselineMaximumRangeRule: SlotBaselineRule {
        var min: Double
        var max: Double

        init(min: Double, max: Double) {
            self.min = min
            self.max = max
        }

        func check(_ item: SlotBaseline) -> [String] {
            let value = item.maximum
            var problems: [String] = []
            if value < min {
                problems.append("maximum \(value) is below \(min)")
            }
            if value > max {
                problems.append("maximum \(value) is above \(max)")
            }
            return problems
        }
    }

    final class SlotBaselineCapacityRangeRule: SlotBaselineRule {
        var min: Int
        var max: Int

        init(min: Int, max: Int) {
            self.min = min
            self.max = max
        }

        func check(_ item: SlotBaseline) -> [String] {
            let value = item.capacity
            if value < min || value > max {
                return ["capacity \(value) is outside \(min) to \(max)"]
            }
            return []
        }
    }

    final class SlotBaselineRequiredLabelRule: SlotBaselineRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: SlotBaseline) -> [String] {
            if item.label.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class SlotBaselineLabelLengthRule: SlotBaselineRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: SlotBaseline) -> [String] {
            let size = item.label.count
            if size > maxLength {
                return ["label is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    /// Runs every rule of a slot baseline.
    final class SlotBaselineValidator {
        var rules: [any SlotBaselineRule]

        init(rules: [any SlotBaselineRule]) {
            self.rules = rules
        }

        func validate(_ item: SlotBaseline) -> [String] {
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

        func requireValid(_ item: SlotBaseline) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.displayLabel()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [SlotBaseline]) -> [String: [String]] {
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

    static func defaultSlotBaselineValidator() -> SlotBaselineValidator {
        return SlotBaselineValidator(
            rules: [
                SlotBaselineRequiredLocaleRule(message: "slot baseline needs an entry"),
                SlotBaselineLocaleLengthRule(maxLength: 3600),
                SlotBaselineMaximumRangeRule(min: 0.6, max: 324.3),
                SlotBaselineCapacityRangeRule(min: 16, max: 120),
                SlotBaselineRequiredLabelRule(message: "slot baseline needs an entry"),
                SlotBaselineLabelLengthRule(maxLength: 86400),
            ]
        )
    }
}
