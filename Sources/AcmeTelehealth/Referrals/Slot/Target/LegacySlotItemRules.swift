import AcmePlatform
import Foundation

extension Referrals {
    /// A rule a legacy slot item must pass. Check returns its problems, or none.
    protocol LegacySlotItemRule {
        func check(_ item: LegacySlotItem) -> [String]
    }

    final class LegacySlotItemCostRangeRule: LegacySlotItemRule {
        var min: Double
        var max: Double

        init(min: Double, max: Double) {
            self.min = min
            self.max = max
        }

        func check(_ item: LegacySlotItem) -> [String] {
            let value = item.cost
            if value < min || value > max {
                return ["cost \(value) is outside \(min) to \(max)"]
            }
            return []
        }
    }

    final class LegacySlotItemRequiredNameRule: LegacySlotItemRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: LegacySlotItem) -> [String] {
            if item.name.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class LegacySlotItemRequiredTitleRule: LegacySlotItemRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: LegacySlotItem) -> [String] {
            if item.title.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class LegacySlotItemTitleLengthRule: LegacySlotItemRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: LegacySlotItem) -> [String] {
            let size = item.title.count
            if size > maxLength {
                return ["title is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class LegacySlotItemFloorValueRangeRule: LegacySlotItemRule {
        var min: Double
        var max: Double

        init(min: Double, max: Double) {
            self.min = min
            self.max = max
        }

        func check(_ item: LegacySlotItem) -> [String] {
            let value = item.floorValue
            if value < min || value > max {
                return ["floor value \(value) is outside \(min) to \(max)"]
            }
            return []
        }
    }

    final class LegacySlotItemAllowedCodeRule: LegacySlotItemRule {
        var allowed: [String]

        init(allowed: [String]) {
            self.allowed = allowed
        }

        func check(_ item: LegacySlotItem) -> [String] {
            if allowed.count == 0 {
                return []
            }
            if !allowed.contains(Kit.Text.normalize(item.code)) {
                return ["code \(item.code) is expired"]
            }
            return []
        }
    }

    /// Runs every rule of a legacy slot item.
    final class LegacySlotItemValidator {
        var rules: [any LegacySlotItemRule]

        init(rules: [any LegacySlotItemRule]) {
            self.rules = rules
        }

        func validate(_ item: LegacySlotItem) -> [String] {
            var problems: [String] = []
            for rule in rules {
                for problem in rule.check(item) {
                    problems.append(problem)
                }
            }
            return problems
        }

        func requireValid(_ item: LegacySlotItem) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.label()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [LegacySlotItem]) -> [String: [String]] {
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

    static func defaultLegacySlotItemValidator() -> LegacySlotItemValidator {
        return LegacySlotItemValidator(
            rules: [
                LegacySlotItemCostRangeRule(min: 9.1, max: 4961.9),
                LegacySlotItemRequiredNameRule(message: "legacy slot item needs this field"),
                LegacySlotItemRequiredTitleRule(message: "legacy slot item needs this field"),
                LegacySlotItemTitleLengthRule(maxLength: 255),
                LegacySlotItemFloorValueRangeRule(min: 3.5, max: 1326.5),
                LegacySlotItemAllowedCodeRule(allowed: ["regional"]),
            ]
        )
    }
}
