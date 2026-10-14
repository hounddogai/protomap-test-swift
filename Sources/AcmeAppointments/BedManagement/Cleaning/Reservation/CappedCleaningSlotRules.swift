import AcmePlatform
import Foundation

extension BedManagement {
    /// A rule a capped cleaning slot must pass. Check returns its problems, or none.
    protocol CappedCleaningSlotRule {
        func check(_ item: CappedCleaningSlot) -> [String]
    }

    final class CappedCleaningSlotDiagnosisCodeLengthRule: CappedCleaningSlotRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: CappedCleaningSlot) -> [String] {
            let size = item.diagnosisCode.count
            if size > maxLength {
                return ["diagnosis code is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class CappedCleaningSlotRequiredCodeRule: CappedCleaningSlotRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: CappedCleaningSlot) -> [String] {
            if item.code.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class CappedCleaningSlotCodePrefixRule: CappedCleaningSlotRule {
        var prefix: String

        init(prefix: String) {
            self.prefix = prefix
        }

        func check(_ item: CappedCleaningSlot) -> [String] {
            if !item.code.uppercased().hasPrefix(prefix.uppercased()) {
                return ["code must start with \(prefix)"]
            }
            return []
        }
    }

    final class CappedCleaningSlotRequiredContactEmailRule: CappedCleaningSlotRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: CappedCleaningSlot) -> [String] {
            if item.contactEmail.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class CappedCleaningSlotAllowedDiagnosisCodeRule: CappedCleaningSlotRule {
        var allowed: [String]

        init(allowed: [String]) {
            self.allowed = allowed
        }

        func check(_ item: CappedCleaningSlot) -> [String] {
            if allowed.count == 0 {
                return []
            }
            if !allowed.contains(Kit.Text.normalize(item.diagnosisCode)) {
                return ["diagnosis code \(item.diagnosisCode) is out of range"]
            }
            return []
        }
    }

    /// Runs every rule of a capped cleaning slot.
    final class CappedCleaningSlotValidator {
        var rules: [any CappedCleaningSlotRule]

        init(rules: [any CappedCleaningSlotRule]) {
            self.rules = rules
        }

        func validate(_ item: CappedCleaningSlot) -> [String] {
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

        func requireValid(_ item: CappedCleaningSlot) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.displayLabel()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [CappedCleaningSlot]) -> [String: [String]] {
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

    static func defaultCappedCleaningSlotValidator() -> CappedCleaningSlotValidator {
        return CappedCleaningSlotValidator(
            rules: [
                CappedCleaningSlotDiagnosisCodeLengthRule(maxLength: 1000),
                CappedCleaningSlotRequiredCodeRule(message: "capped cleaning slot needs this field"),
                CappedCleaningSlotCodePrefixRule(prefix: "OPS"),
                CappedCleaningSlotRequiredContactEmailRule(message: "capped cleaning slot needs this field"),
                CappedCleaningSlotAllowedDiagnosisCodeRule(allowed: []),
            ]
        )
    }
}
