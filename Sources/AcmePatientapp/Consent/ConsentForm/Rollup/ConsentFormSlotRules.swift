import AcmePlatform
import Foundation

extension Consent {
    /// A rule a consent form slot must pass. Check returns its problems, or none.
    protocol ConsentFormSlotRule {
        func check(_ item: ConsentFormSlot) -> [String]
    }

    final class ConsentFormSlotRequiredPayerRule: ConsentFormSlotRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: ConsentFormSlot) -> [String] {
            if item.payer.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class ConsentFormSlotCodeLengthRule: ConsentFormSlotRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: ConsentFormSlot) -> [String] {
            let size = item.code.count
            if size > maxLength {
                return ["code is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class ConsentFormSlotRequiredCodeRule: ConsentFormSlotRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: ConsentFormSlot) -> [String] {
            if item.code.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class ConsentFormSlotCodePrefixRule: ConsentFormSlotRule {
        var prefix: String

        init(prefix: String) {
            self.prefix = prefix
        }

        func check(_ item: ConsentFormSlot) -> [String] {
            if !item.code.uppercased().hasPrefix(prefix.uppercased()) {
                return ["code must start with \(prefix)"]
            }
            return []
        }
    }

    final class ConsentFormSlotNameLengthRule: ConsentFormSlotRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: ConsentFormSlot) -> [String] {
            let size = item.name.count
            if size > maxLength {
                return ["name is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class ConsentFormSlotDosageMgRangeRule: ConsentFormSlotRule {
        var min: Double
        var max: Double

        init(min: Double, max: Double) {
            self.min = min
            self.max = max
        }

        func check(_ item: ConsentFormSlot) -> [String] {
            let value = item.dosageMg
            var problems: [String] = []
            if value < min {
                problems.append("dosage mg \(value) is below \(min)")
            }
            if value > max {
                problems.append("dosage mg \(value) is above \(max)")
            }
            return problems
        }
    }

    /// Runs every rule of a consent form slot.
    final class ConsentFormSlotValidator {
        var rules: [any ConsentFormSlotRule]

        init(rules: [any ConsentFormSlotRule]) {
            self.rules = rules
        }

        func validate(_ item: ConsentFormSlot) -> [String] {
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

        func requireValid(_ item: ConsentFormSlot) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.label()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [ConsentFormSlot]) -> [String: [String]] {
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

    static func defaultConsentFormSlotValidator() -> ConsentFormSlotValidator {
        return ConsentFormSlotValidator(
            rules: [
                ConsentFormSlotRequiredPayerRule(message: "consent form slot needs a value"),
                ConsentFormSlotCodeLengthRule(maxLength: 16),
                ConsentFormSlotRequiredCodeRule(message: "consent form slot needs this field"),
                ConsentFormSlotCodePrefixRule(prefix: "OPS"),
                ConsentFormSlotNameLengthRule(maxLength: 120),
                ConsentFormSlotDosageMgRangeRule(min: 5.7, max: 3699.0),
            ]
        )
    }
}
