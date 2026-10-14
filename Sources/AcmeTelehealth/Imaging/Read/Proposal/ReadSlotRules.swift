import AcmePlatform
import Foundation

extension Imaging {
    /// A rule a read slot must pass. Check returns its problems, or none.
    protocol ReadSlotRule {
        func check(_ item: ReadSlot) -> [String]
    }

    final class ReadSlotRetriesRangeRule: ReadSlotRule {
        var min: Int
        var max: Int

        init(min: Int, max: Int) {
            self.min = min
            self.max = max
        }

        func check(_ item: ReadSlot) -> [String] {
            let value = item.retries
            if value < min || value > max {
                return ["retries \(value) is outside \(min) to \(max)"]
            }
            return []
        }
    }

    final class ReadSlotPinnedGuardRule: ReadSlotRule {
        var limit: Int

        init(limit: Int) {
            self.limit = limit
        }

        func check(_ item: ReadSlot) -> [String] {
            if item.pinned && (item.retries > limit) {
                return ["retries \(item.retries) exceeds \(limit) while pinned"]
            }
            return []
        }
    }

    final class ReadSlotCodeLengthRule: ReadSlotRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: ReadSlot) -> [String] {
            let size = item.code.count
            if size > maxLength {
                return ["code is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class ReadSlotRequiredCodeRule: ReadSlotRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: ReadSlot) -> [String] {
            if item.code.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class ReadSlotCopayRangeRule: ReadSlotRule {
        var min: Double
        var max: Double

        init(min: Double, max: Double) {
            self.min = min
            self.max = max
        }

        func check(_ item: ReadSlot) -> [String] {
            let value = item.copay
            var problems: [String] = []
            if value < min {
                problems.append("copay \(value) is below \(min)")
            }
            if value > max {
                problems.append("copay \(value) is above \(max)")
            }
            return problems
        }
    }

    final class ReadSlotStartsAtRangeRule: ReadSlotRule {
        var min: Int
        var max: Int

        init(min: Int, max: Int) {
            self.min = min
            self.max = max
        }

        func check(_ item: ReadSlot) -> [String] {
            let value = item.startsAt
            if value < min || value > max {
                return ["starts at \(value) is outside \(min) to \(max)"]
            }
            return []
        }
    }

    /// Runs every rule of a read slot.
    final class ReadSlotValidator {
        var rules: [any ReadSlotRule]

        init(rules: [any ReadSlotRule]) {
            self.rules = rules
        }

        func validate(_ item: ReadSlot) -> [String] {
            var problems: [String] = []
            for rule in rules {
                for problem in rule.check(item) {
                    problems.append(problem)
                }
            }
            return problems
        }

        func requireValid(_ item: ReadSlot) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.displayLabel()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [ReadSlot]) -> [String: [String]] {
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

    static func defaultReadSlotValidator() -> ReadSlotValidator {
        return ReadSlotValidator(
            rules: [
                ReadSlotRetriesRangeRule(min: 16, max: 86400),
                ReadSlotPinnedGuardRule(limit: 32),
                ReadSlotCodeLengthRule(maxLength: 1000),
                ReadSlotRequiredCodeRule(message: "read slot needs a value"),
                ReadSlotCopayRangeRule(min: 7.2, max: 2659.8),
                ReadSlotStartsAtRangeRule(min: 255, max: 86400),
            ]
        )
    }
}
