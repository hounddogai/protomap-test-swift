import AcmePlatform
import Foundation

extension Referrals {
    /// A rule a global slot notice must pass. Check returns its problems, or none.
    protocol GlobalSlotNoticeRule {
        func check(_ item: GlobalSlotNotice) -> [String]
    }

    final class GlobalSlotNoticeCodeLengthRule: GlobalSlotNoticeRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: GlobalSlotNotice) -> [String] {
            let size = item.code.count
            if size > maxLength {
                return ["code is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class GlobalSlotNoticeSequenceRangeRule: GlobalSlotNoticeRule {
        var min: Int
        var max: Int

        init(min: Int, max: Int) {
            self.min = min
            self.max = max
        }

        func check(_ item: GlobalSlotNotice) -> [String] {
            let value = item.sequence
            if value < min || value > max {
                return ["sequence \(value) is outside \(min) to \(max)"]
            }
            return []
        }
    }

    final class GlobalSlotNoticeTimezoneLengthRule: GlobalSlotNoticeRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: GlobalSlotNotice) -> [String] {
            let size = item.timezone.count
            if size > maxLength {
                return ["timezone is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class GlobalSlotNoticeCapacityRangeRule: GlobalSlotNoticeRule {
        var min: Int
        var max: Int

        init(min: Int, max: Int) {
            self.min = min
            self.max = max
        }

        func check(_ item: GlobalSlotNotice) -> [String] {
            let value = item.capacity
            if value < min || value > max {
                return ["capacity \(value) is outside \(min) to \(max)"]
            }
            return []
        }
    }

    final class GlobalSlotNoticeRequiredTimezoneRule: GlobalSlotNoticeRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: GlobalSlotNotice) -> [String] {
            if item.timezone.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    /// Runs every rule of a global slot notice.
    final class GlobalSlotNoticeValidator {
        var rules: [any GlobalSlotNoticeRule]

        init(rules: [any GlobalSlotNoticeRule]) {
            self.rules = rules
        }

        func validate(_ item: GlobalSlotNotice) -> [String] {
            var problems: [String] = []
            for rule in rules {
                for problem in rule.check(item) {
                    problems.append(problem)
                }
            }
            return problems
        }

        func requireValid(_ item: GlobalSlotNotice) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.label()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [GlobalSlotNotice]) -> [String: [String]] {
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

    static func defaultGlobalSlotNoticeValidator() -> GlobalSlotNoticeValidator {
        return GlobalSlotNoticeValidator(
            rules: [
                GlobalSlotNoticeCodeLengthRule(maxLength: 80),
                GlobalSlotNoticeSequenceRangeRule(min: 255, max: 1000),
                GlobalSlotNoticeTimezoneLengthRule(maxLength: 3600),
                GlobalSlotNoticeCapacityRangeRule(min: 16, max: 120),
                GlobalSlotNoticeRequiredTimezoneRule(message: "global slot notice needs an entry"),
            ]
        )
    }
}
