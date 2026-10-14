import AcmePlatform
import Foundation

extension ClinicalOps {
    /// A rule a fallback rounding slot must pass. Check returns its problems, or none.
    protocol FallbackRoundingSlotRule {
        func check(_ item: FallbackRoundingSlot) -> [String]
    }

    final class FallbackRoundingSlotRequiredChecksumRule: FallbackRoundingSlotRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: FallbackRoundingSlot) -> [String] {
            if item.checksum.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class FallbackRoundingSlotAllowedPatientRefRule: FallbackRoundingSlotRule {
        var allowed: [String]

        init(allowed: [String]) {
            self.allowed = allowed
        }

        func check(_ item: FallbackRoundingSlot) -> [String] {
            if allowed.count == 0 {
                return []
            }
            if !allowed.contains(Kit.Text.normalize(item.patientRef)) {
                return ["patient ref \(item.patientRef) is unknown"]
            }
            return []
        }
    }

    final class FallbackRoundingSlotDiscountRangeRule: FallbackRoundingSlotRule {
        var min: Double
        var max: Double

        init(min: Double, max: Double) {
            self.min = min
            self.max = max
        }

        func check(_ item: FallbackRoundingSlot) -> [String] {
            let value = item.discount
            if value < min || value > max {
                return ["discount \(value) is outside \(min) to \(max)"]
            }
            return []
        }
    }

    final class FallbackRoundingSlotPatientRefLengthRule: FallbackRoundingSlotRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: FallbackRoundingSlot) -> [String] {
            let size = item.patientRef.count
            if size > maxLength {
                return ["patient ref is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    /// Runs every rule of a fallback rounding slot.
    final class FallbackRoundingSlotValidator {
        var rules: [any FallbackRoundingSlotRule]

        init(rules: [any FallbackRoundingSlotRule]) {
            self.rules = rules
        }

        func validate(_ item: FallbackRoundingSlot) -> [String] {
            var problems: [String] = []
            for rule in rules {
                for problem in rule.check(item) {
                    problems.append(problem)
                }
            }
            return problems
        }

        func requireValid(_ item: FallbackRoundingSlot) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.label()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [FallbackRoundingSlot]) -> [String: [String]] {
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

    static func defaultFallbackRoundingSlotValidator() -> FallbackRoundingSlotValidator {
        return FallbackRoundingSlotValidator(
            rules: [
                FallbackRoundingSlotRequiredChecksumRule(message: "fallback rounding slot needs a value"),
                FallbackRoundingSlotAllowedPatientRefRule(allowed: ["global", "adaptive"]),
                FallbackRoundingSlotDiscountRangeRule(min: 4.4, max: 247.3),
                FallbackRoundingSlotPatientRefLengthRule(maxLength: 120),
            ]
        )
    }
}
