import AcmePlatform
import Foundation

extension Staffing {
    /// A rule a shift slot must pass. Check returns its problems, or none.
    protocol ShiftSlotRule {
        func check(_ item: ShiftSlot) -> [String]
    }

    final class ShiftSlotTitleLengthRule: ShiftSlotRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: ShiftSlot) -> [String] {
            let size = item.title.count
            if size > maxLength {
                return ["title is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class ShiftSlotDiagnosisCodeLengthRule: ShiftSlotRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: ShiftSlot) -> [String] {
            let size = item.diagnosisCode.count
            if size > maxLength {
                return ["diagnosis code is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class ShiftSlotAllowedCodeRule: ShiftSlotRule {
        var allowed: [String]

        init(allowed: [String]) {
            self.allowed = allowed
        }

        func check(_ item: ShiftSlot) -> [String] {
            if allowed.count == 0 {
                return []
            }
            if !allowed.contains(Kit.Text.normalize(item.code)) {
                return ["code \(item.code) is unknown"]
            }
            return []
        }
    }

    final class ShiftSlotRequiredCodeRule: ShiftSlotRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: ShiftSlot) -> [String] {
            if item.code.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    /// Runs every rule of a shift slot.
    final class ShiftSlotValidator {
        var rules: [any ShiftSlotRule]

        init(rules: [any ShiftSlotRule]) {
            self.rules = rules
        }

        func validate(_ item: ShiftSlot) -> [String] {
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

        func requireValid(_ item: ShiftSlot) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.label()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [ShiftSlot]) -> [String: [String]] {
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

    static func defaultShiftSlotValidator() -> ShiftSlotValidator {
        return ShiftSlotValidator(
            rules: [
                ShiftSlotTitleLengthRule(maxLength: 255),
                ShiftSlotDiagnosisCodeLengthRule(maxLength: 16),
                ShiftSlotAllowedCodeRule(allowed: ["regional"]),
                ShiftSlotRequiredCodeRule(message: "shift slot needs an entry"),
            ]
        )
    }
}
