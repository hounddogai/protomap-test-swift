import AcmePlatform
import Foundation

extension Imaging {
    /// A rule a modality slot must pass. Check returns its problems, or none.
    protocol ModalitySlotRule {
        func check(_ item: ModalitySlot) -> [String]
    }

    final class ModalitySlotAllowedNameRule: ModalitySlotRule {
        var allowed: [String]

        init(allowed: [String]) {
            self.allowed = allowed
        }

        func check(_ item: ModalitySlot) -> [String] {
            if allowed.count == 0 {
                return []
            }
            if !allowed.contains(Kit.Text.normalize(item.name)) {
                return ["name \(item.name) is inconsistent"]
            }
            return []
        }
    }

    final class ModalitySlotCodeLengthRule: ModalitySlotRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: ModalitySlot) -> [String] {
            let size = item.code.count
            if size > maxLength {
                return ["code is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class ModalitySlotCeilingRangeRule: ModalitySlotRule {
        var min: Double
        var max: Double

        init(min: Double, max: Double) {
            self.min = min
            self.max = max
        }

        func check(_ item: ModalitySlot) -> [String] {
            let value = item.ceiling
            var problems: [String] = []
            if value < min {
                problems.append("ceiling \(value) is below \(min)")
            }
            if value > max {
                problems.append("ceiling \(value) is above \(max)")
            }
            return problems
        }
    }

    final class ModalitySlotRequiredNameRule: ModalitySlotRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: ModalitySlot) -> [String] {
            if item.name.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    /// Runs every rule of a modality slot.
    final class ModalitySlotValidator {
        var rules: [any ModalitySlotRule]

        init(rules: [any ModalitySlotRule]) {
            self.rules = rules
        }

        func validate(_ item: ModalitySlot) -> [String] {
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

        func requireValid(_ item: ModalitySlot) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.displayLabel()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [ModalitySlot]) -> [String: [String]] {
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

    static func defaultModalitySlotValidator() -> ModalitySlotValidator {
        return ModalitySlotValidator(
            rules: [
                ModalitySlotAllowedNameRule(allowed: ["strict"]),
                ModalitySlotCodeLengthRule(maxLength: 1000),
                ModalitySlotCeilingRangeRule(min: 6.9, max: 4791.3),
                ModalitySlotRequiredNameRule(message: "modality slot needs an entry"),
            ]
        )
    }
}
