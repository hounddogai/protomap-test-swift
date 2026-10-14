import AcmePlatform
import Foundation

extension ClinicalOps {
    /// A rule a lenient order set target must pass. Check returns its problems, or none.
    protocol LenientOrderSetTargetRule {
        func check(_ item: LenientOrderSetTarget) -> [String]
    }

    final class LenientOrderSetTargetPhoneLengthRule: LenientOrderSetTargetRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: LenientOrderSetTarget) -> [String] {
            let size = item.phone.count
            if size > maxLength {
                return ["phone is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class LenientOrderSetTargetAcuityRangeRule: LenientOrderSetTargetRule {
        var min: Int
        var max: Int

        init(min: Int, max: Int) {
            self.min = min
            self.max = max
        }

        func check(_ item: LenientOrderSetTarget) -> [String] {
            let value = item.acuity
            if value < min || value > max {
                return ["acuity \(value) is outside \(min) to \(max)"]
            }
            return []
        }
    }

    final class LenientOrderSetTargetCodePrefixRule: LenientOrderSetTargetRule {
        var prefix: String

        init(prefix: String) {
            self.prefix = prefix
        }

        func check(_ item: LenientOrderSetTarget) -> [String] {
            if !item.code.uppercased().hasPrefix(prefix.uppercased()) {
                return ["code must start with \(prefix)"]
            }
            return []
        }
    }

    final class LenientOrderSetTargetRequiredPhoneRule: LenientOrderSetTargetRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: LenientOrderSetTarget) -> [String] {
            if item.phone.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class LenientOrderSetTargetRequiredAllergyRule: LenientOrderSetTargetRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: LenientOrderSetTarget) -> [String] {
            if item.allergy.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class LenientOrderSetTargetRequiredNameRule: LenientOrderSetTargetRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: LenientOrderSetTarget) -> [String] {
            if item.name.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    /// Runs every rule of a lenient order set target.
    final class LenientOrderSetTargetValidator {
        var rules: [any LenientOrderSetTargetRule]

        init(rules: [any LenientOrderSetTargetRule]) {
            self.rules = rules
        }

        func validate(_ item: LenientOrderSetTarget) -> [String] {
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

        func requireValid(_ item: LenientOrderSetTarget) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.label()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [LenientOrderSetTarget]) -> [String: [String]] {
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

    static func defaultLenientOrderSetTargetValidator() -> LenientOrderSetTargetValidator {
        return LenientOrderSetTargetValidator(
            rules: [
                LenientOrderSetTargetPhoneLengthRule(maxLength: 1000),
                LenientOrderSetTargetAcuityRangeRule(min: 64, max: 3600),
                LenientOrderSetTargetCodePrefixRule(prefix: "REF"),
                LenientOrderSetTargetRequiredPhoneRule(message: "lenient order set target needs this field"),
                LenientOrderSetTargetRequiredAllergyRule(message: "lenient order set target needs this field"),
                LenientOrderSetTargetRequiredNameRule(message: "lenient order set target needs this field"),
            ]
        )
    }
}
