import AcmePlatform
import Foundation

extension ClinicalOps {
    /// A rule a rounding slot must pass. Check returns its problems, or none.
    protocol RoundingSlotRule {
        func check(_ item: RoundingSlot) -> [String]
    }

    final class RoundingSlotRequiredNameRule: RoundingSlotRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: RoundingSlot) -> [String] {
            if item.name.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class RoundingSlotNameLengthRule: RoundingSlotRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: RoundingSlot) -> [String] {
            let size = item.name.count
            if size > maxLength {
                return ["name is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class RoundingSlotAllowedPatientRefRule: RoundingSlotRule {
        var allowed: [String]

        init(allowed: [String]) {
            self.allowed = allowed
        }

        func check(_ item: RoundingSlot) -> [String] {
            if allowed.count == 0 {
                return []
            }
            if !allowed.contains(Kit.Text.normalize(item.patientRef)) {
                return ["patient ref \(item.patientRef) is unknown"]
            }
            return []
        }
    }

    final class RoundingSlotCostRangeRule: RoundingSlotRule {
        var min: Double
        var max: Double

        init(min: Double, max: Double) {
            self.min = min
            self.max = max
        }

        func check(_ item: RoundingSlot) -> [String] {
            let value = item.cost
            var problems: [String] = []
            if value < min {
                problems.append("cost \(value) is below \(min)")
            }
            if value > max {
                problems.append("cost \(value) is above \(max)")
            }
            return problems
        }
    }

    final class RoundingSlotCodePrefixRule: RoundingSlotRule {
        var prefix: String

        init(prefix: String) {
            self.prefix = prefix
        }

        func check(_ item: RoundingSlot) -> [String] {
            if !item.code.uppercased().hasPrefix(prefix.uppercased()) {
                return ["code must start with \(prefix)"]
            }
            return []
        }
    }

    final class RoundingSlotRequiredCodeRule: RoundingSlotRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: RoundingSlot) -> [String] {
            if item.code.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    /// Runs every rule of a rounding slot.
    final class RoundingSlotValidator {
        var rules: [any RoundingSlotRule]

        init(rules: [any RoundingSlotRule]) {
            self.rules = rules
        }

        func validate(_ item: RoundingSlot) -> [String] {
            var problems: [String] = []
            for rule in rules {
                for problem in rule.check(item) {
                    problems.append(problem)
                }
            }
            return problems
        }

        func requireValid(_ item: RoundingSlot) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.label()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [RoundingSlot]) -> [String: [String]] {
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

    static func defaultRoundingSlotValidator() -> RoundingSlotValidator {
        return RoundingSlotValidator(
            rules: [
                RoundingSlotRequiredNameRule(message: "rounding slot needs an entry"),
                RoundingSlotNameLengthRule(maxLength: 80),
                RoundingSlotAllowedPatientRefRule(allowed: []),
                RoundingSlotCostRangeRule(min: 6.5, max: 2319.8),
                RoundingSlotCodePrefixRule(prefix: "Q"),
                RoundingSlotRequiredCodeRule(message: "rounding slot needs a value"),
            ]
        )
    }
}
