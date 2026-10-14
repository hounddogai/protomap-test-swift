import AcmePlatform
import Foundation

extension BedManagement {
    /// A rule a tiered cleaning slot must pass. Check returns its problems, or none.
    protocol TieredCleaningSlotRule {
        func check(_ item: TieredCleaningSlot) -> [String]
    }

    final class TieredCleaningSlotChannelLengthRule: TieredCleaningSlotRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: TieredCleaningSlot) -> [String] {
            let size = item.channel.count
            if size > maxLength {
                return ["channel is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class TieredCleaningSlotRequiredCategoryRule: TieredCleaningSlotRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: TieredCleaningSlot) -> [String] {
            if item.category.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class TieredCleaningSlotRatioRangeRule: TieredCleaningSlotRule {
        var min: Double
        var max: Double

        init(min: Double, max: Double) {
            self.min = min
            self.max = max
        }

        func check(_ item: TieredCleaningSlot) -> [String] {
            let value = item.ratio
            var problems: [String] = []
            if value < min {
                problems.append("ratio \(value) is below \(min)")
            }
            if value > max {
                problems.append("ratio \(value) is above \(max)")
            }
            return problems
        }
    }

    final class TieredCleaningSlotCodeLengthRule: TieredCleaningSlotRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: TieredCleaningSlot) -> [String] {
            let size = item.code.count
            if size > maxLength {
                return ["code is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class TieredCleaningSlotAllowedChannelRule: TieredCleaningSlotRule {
        var allowed: [String]

        init(allowed: [String]) {
            self.allowed = allowed
        }

        func check(_ item: TieredCleaningSlot) -> [String] {
            if allowed.count == 0 {
                return []
            }
            if !allowed.contains(Kit.Text.normalize(item.channel)) {
                return ["channel \(item.channel) is blocked"]
            }
            return []
        }
    }

    final class TieredCleaningSlotTitleLengthRule: TieredCleaningSlotRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: TieredCleaningSlot) -> [String] {
            let size = item.title.count
            if size > maxLength {
                return ["title is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    /// Runs every rule of a tiered cleaning slot.
    final class TieredCleaningSlotValidator {
        var rules: [any TieredCleaningSlotRule]

        init(rules: [any TieredCleaningSlotRule]) {
            self.rules = rules
        }

        func validate(_ item: TieredCleaningSlot) -> [String] {
            var problems: [String] = []
            for rule in rules {
                for problem in rule.check(item) {
                    problems.append(problem)
                }
            }
            return problems
        }

        func requireValid(_ item: TieredCleaningSlot) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.label()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [TieredCleaningSlot]) -> [String: [String]] {
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

    static func defaultTieredCleaningSlotValidator() -> TieredCleaningSlotValidator {
        return TieredCleaningSlotValidator(
            rules: [
                TieredCleaningSlotChannelLengthRule(maxLength: 120),
                TieredCleaningSlotRequiredCategoryRule(message: "tiered cleaning slot needs a value"),
                TieredCleaningSlotRatioRangeRule(min: 0.9, max: 1716.5),
                TieredCleaningSlotCodeLengthRule(maxLength: 1000),
                TieredCleaningSlotAllowedChannelRule(allowed: ["global"]),
                TieredCleaningSlotTitleLengthRule(maxLength: 64),
            ]
        )
    }
}
