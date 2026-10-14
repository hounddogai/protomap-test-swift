import AcmePlatform
import Foundation

extension Labs {
    /// A rule a panel slot must pass. Check returns its problems, or none.
    protocol PanelSlotRule {
        func check(_ item: PanelSlot) -> [String]
    }

    final class PanelSlotRequiredReviewerRule: PanelSlotRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: PanelSlot) -> [String] {
            if item.reviewer.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class PanelSlotMinimumRangeRule: PanelSlotRule {
        var min: Double
        var max: Double

        init(min: Double, max: Double) {
            self.min = min
            self.max = max
        }

        func check(_ item: PanelSlot) -> [String] {
            let value = item.minimum
            var problems: [String] = []
            if value < min {
                problems.append("minimum \(value) is below \(min)")
            }
            if value > max {
                problems.append("minimum \(value) is above \(max)")
            }
            return problems
        }
    }

    final class PanelSlotRequiredLabelRule: PanelSlotRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: PanelSlot) -> [String] {
            if item.label.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class PanelSlotCodeLengthRule: PanelSlotRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: PanelSlot) -> [String] {
            let size = item.code.count
            if size > maxLength {
                return ["code is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    /// Runs every rule of a panel slot.
    final class PanelSlotValidator {
        var rules: [any PanelSlotRule]

        init(rules: [any PanelSlotRule]) {
            self.rules = rules
        }

        func validate(_ item: PanelSlot) -> [String] {
            var problems: [String] = []
            for rule in rules {
                for problem in rule.check(item) {
                    problems.append(problem)
                }
            }
            return problems
        }

        func requireValid(_ item: PanelSlot) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.displayLabel()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [PanelSlot]) -> [String: [String]] {
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

    static func defaultPanelSlotValidator() -> PanelSlotValidator {
        return PanelSlotValidator(
            rules: [
                PanelSlotRequiredReviewerRule(message: "panel slot needs this field"),
                PanelSlotMinimumRangeRule(min: 2.2, max: 2788.4),
                PanelSlotRequiredLabelRule(message: "panel slot needs an entry"),
                PanelSlotCodeLengthRule(maxLength: 120),
            ]
        )
    }
}
