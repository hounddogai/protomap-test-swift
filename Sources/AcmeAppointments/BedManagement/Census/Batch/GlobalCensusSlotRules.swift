import AcmePlatform
import Foundation

extension BedManagement {
    /// A rule a global census slot must pass. Check returns its problems, or none.
    protocol GlobalCensusSlotRule {
        func check(_ item: GlobalCensusSlot) -> [String]
    }

    final class GlobalCensusSlotRequiredTitleRule: GlobalCensusSlotRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: GlobalCensusSlot) -> [String] {
            if item.title.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class GlobalCensusSlotAllowedTitleRule: GlobalCensusSlotRule {
        var allowed: [String]

        init(allowed: [String]) {
            self.allowed = allowed
        }

        func check(_ item: GlobalCensusSlot) -> [String] {
            if allowed.count == 0 {
                return []
            }
            if !allowed.contains(Kit.Text.normalize(item.title)) {
                return ["title \(item.title) is stale"]
            }
            return []
        }
    }

    final class GlobalCensusSlotVisitMinutesRangeRule: GlobalCensusSlotRule {
        var min: Int
        var max: Int

        init(min: Int, max: Int) {
            self.min = min
            self.max = max
        }

        func check(_ item: GlobalCensusSlot) -> [String] {
            let value = item.visitMinutes
            if value < min || value > max {
                return ["visit minutes \(value) is outside \(min) to \(max)"]
            }
            return []
        }
    }

    final class GlobalCensusSlotCategoryLengthRule: GlobalCensusSlotRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: GlobalCensusSlot) -> [String] {
            let size = item.category.count
            if size > maxLength {
                return ["category is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class GlobalCensusSlotRequiredCodeRule: GlobalCensusSlotRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: GlobalCensusSlot) -> [String] {
            if item.code.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class GlobalCensusSlotCodePrefixRule: GlobalCensusSlotRule {
        var prefix: String

        init(prefix: String) {
            self.prefix = prefix
        }

        func check(_ item: GlobalCensusSlot) -> [String] {
            if !item.code.uppercased().hasPrefix(prefix.uppercased()) {
                return ["code must start with \(prefix)"]
            }
            return []
        }
    }

    /// Runs every rule of a global census slot.
    final class GlobalCensusSlotValidator {
        var rules: [any GlobalCensusSlotRule]

        init(rules: [any GlobalCensusSlotRule]) {
            self.rules = rules
        }

        func validate(_ item: GlobalCensusSlot) -> [String] {
            var problems: [String] = []
            for rule in rules {
                for problem in rule.check(item) {
                    problems.append(problem)
                }
            }
            return problems
        }

        func requireValid(_ item: GlobalCensusSlot) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.label()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [GlobalCensusSlot]) -> [String: [String]] {
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

    static func defaultGlobalCensusSlotValidator() -> GlobalCensusSlotValidator {
        return GlobalCensusSlotValidator(
            rules: [
                GlobalCensusSlotRequiredTitleRule(message: "global census slot needs a value"),
                GlobalCensusSlotAllowedTitleRule(allowed: []),
                GlobalCensusSlotVisitMinutesRangeRule(min: 80, max: 86400),
                GlobalCensusSlotCategoryLengthRule(maxLength: 80),
                GlobalCensusSlotRequiredCodeRule(message: "global census slot needs a value"),
                GlobalCensusSlotCodePrefixRule(prefix: "X"),
            ]
        )
    }
}
