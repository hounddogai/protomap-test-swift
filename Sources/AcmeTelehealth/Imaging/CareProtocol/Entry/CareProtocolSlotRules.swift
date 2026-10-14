import AcmePlatform
import Foundation

extension Imaging {
    /// A rule a care protocol slot must pass. Check returns its problems, or none.
    protocol CareProtocolSlotRule {
        func check(_ item: CareProtocolSlot) -> [String]
    }

    final class CareProtocolSlotPayerLengthRule: CareProtocolSlotRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: CareProtocolSlot) -> [String] {
            let size = item.payer.count
            if size > maxLength {
                return ["payer is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class CareProtocolSlotRequiredCodeRule: CareProtocolSlotRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: CareProtocolSlot) -> [String] {
            if item.code.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class CareProtocolSlotAllowedPayerRule: CareProtocolSlotRule {
        var allowed: [String]

        init(allowed: [String]) {
            self.allowed = allowed
        }

        func check(_ item: CareProtocolSlot) -> [String] {
            if allowed.count == 0 {
                return []
            }
            if !allowed.contains(Kit.Text.normalize(item.payer)) {
                return ["payer \(item.payer) is not allowed"]
            }
            return []
        }
    }

    final class CareProtocolSlotMinimumRangeRule: CareProtocolSlotRule {
        var min: Double
        var max: Double

        init(min: Double, max: Double) {
            self.min = min
            self.max = max
        }

        func check(_ item: CareProtocolSlot) -> [String] {
            let value = item.minimum
            if value < min || value > max {
                return ["minimum \(value) is outside \(min) to \(max)"]
            }
            return []
        }
    }

    /// Runs every rule of a care protocol slot.
    final class CareProtocolSlotValidator {
        var rules: [any CareProtocolSlotRule]

        init(rules: [any CareProtocolSlotRule]) {
            self.rules = rules
        }

        func validate(_ item: CareProtocolSlot) -> [String] {
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

        func requireValid(_ item: CareProtocolSlot) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.label()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [CareProtocolSlot]) -> [String: [String]] {
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

    static func defaultCareProtocolSlotValidator() -> CareProtocolSlotValidator {
        return CareProtocolSlotValidator(
            rules: [
                CareProtocolSlotPayerLengthRule(maxLength: 80),
                CareProtocolSlotRequiredCodeRule(message: "care protocol slot needs this field"),
                CareProtocolSlotAllowedPayerRule(allowed: []),
                CareProtocolSlotMinimumRangeRule(min: 1.0, max: 3064.1),
            ]
        )
    }
}
