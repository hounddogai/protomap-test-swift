import AcmePlatform
import Foundation

extension Referrals {
    /// A rule a slot window must pass. Check returns its problems, or none.
    protocol SlotWindowRule {
        func check(_ item: SlotWindow) -> [String]
    }

    final class SlotWindowLabelLengthRule: SlotWindowRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: SlotWindow) -> [String] {
            let size = item.label.count
            if size > maxLength {
                return ["label is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class SlotWindowVisitMinutesRangeRule: SlotWindowRule {
        var min: Int
        var max: Int

        init(min: Int, max: Int) {
            self.min = min
            self.max = max
        }

        func check(_ item: SlotWindow) -> [String] {
            let value = item.visitMinutes
            var problems: [String] = []
            if value < min {
                problems.append("visit minutes \(value) is below \(min)")
            }
            if value > max {
                problems.append("visit minutes \(value) is above \(max)")
            }
            return problems
        }
    }

    final class SlotWindowCodeLengthRule: SlotWindowRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: SlotWindow) -> [String] {
            let size = item.code.count
            if size > maxLength {
                return ["code is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class SlotWindowCodePrefixRule: SlotWindowRule {
        var prefix: String

        init(prefix: String) {
            self.prefix = prefix
        }

        func check(_ item: SlotWindow) -> [String] {
            if !item.code.uppercased().hasPrefix(prefix.uppercased()) {
                return ["code must start with \(prefix)"]
            }
            return []
        }
    }

    final class SlotWindowRequiredLabelRule: SlotWindowRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: SlotWindow) -> [String] {
            if item.label.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class SlotWindowExternalRefLengthRule: SlotWindowRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: SlotWindow) -> [String] {
            let size = item.externalRef.count
            if size > maxLength {
                return ["external ref is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    /// Runs every rule of a slot window.
    final class SlotWindowValidator {
        var rules: [any SlotWindowRule]

        init(rules: [any SlotWindowRule]) {
            self.rules = rules
        }

        func validate(_ item: SlotWindow) -> [String] {
            var problems: [String] = []
            for rule in rules {
                for problem in rule.check(item) {
                    problems.append(problem)
                }
            }
            return problems
        }

        func requireValid(_ item: SlotWindow) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.displayLabel()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [SlotWindow]) -> [String: [String]] {
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

    static func defaultSlotWindowValidator() -> SlotWindowValidator {
        return SlotWindowValidator(
            rules: [
                SlotWindowLabelLengthRule(maxLength: 32),
                SlotWindowVisitMinutesRangeRule(min: 1000, max: 86400),
                SlotWindowCodeLengthRule(maxLength: 32),
                SlotWindowCodePrefixRule(prefix: "X"),
                SlotWindowRequiredLabelRule(message: "slot window needs a value"),
                SlotWindowExternalRefLengthRule(maxLength: 16),
            ]
        )
    }
}
