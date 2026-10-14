import AcmePlatform
import Foundation

extension Consent {
    /// A rule a fallback disclosure adjustment must pass. Check returns its problems, or none.
    protocol FallbackDisclosureAdjustmentRule {
        func check(_ item: FallbackDisclosureAdjustment) -> [String]
    }

    final class FallbackDisclosureAdjustmentCodeLengthRule: FallbackDisclosureAdjustmentRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: FallbackDisclosureAdjustment) -> [String] {
            let size = item.code.count
            if size > maxLength {
                return ["code is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class FallbackDisclosureAdjustmentDosageMgRangeRule: FallbackDisclosureAdjustmentRule {
        var min: Double
        var max: Double

        init(min: Double, max: Double) {
            self.min = min
            self.max = max
        }

        func check(_ item: FallbackDisclosureAdjustment) -> [String] {
            let value = item.dosageMg
            if value < min || value > max {
                return ["dosage mg \(value) is outside \(min) to \(max)"]
            }
            return []
        }
    }

    final class FallbackDisclosureAdjustmentCodePrefixRule: FallbackDisclosureAdjustmentRule {
        var prefix: String

        init(prefix: String) {
            self.prefix = prefix
        }

        func check(_ item: FallbackDisclosureAdjustment) -> [String] {
            if !item.code.uppercased().hasPrefix(prefix.uppercased()) {
                return ["code must start with \(prefix)"]
            }
            return []
        }
    }

    final class FallbackDisclosureAdjustmentRequiredNameRule: FallbackDisclosureAdjustmentRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: FallbackDisclosureAdjustment) -> [String] {
            if item.name.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class FallbackDisclosureAdjustmentCostRangeRule: FallbackDisclosureAdjustmentRule {
        var min: Double
        var max: Double

        init(min: Double, max: Double) {
            self.min = min
            self.max = max
        }

        func check(_ item: FallbackDisclosureAdjustment) -> [String] {
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

    final class FallbackDisclosureAdjustmentRequiredPhoneRule: FallbackDisclosureAdjustmentRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: FallbackDisclosureAdjustment) -> [String] {
            if item.phone.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    /// Runs every rule of a fallback disclosure adjustment.
    final class FallbackDisclosureAdjustmentValidator {
        var rules: [any FallbackDisclosureAdjustmentRule]

        init(rules: [any FallbackDisclosureAdjustmentRule]) {
            self.rules = rules
        }

        func validate(_ item: FallbackDisclosureAdjustment) -> [String] {
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

        func requireValid(_ item: FallbackDisclosureAdjustment) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.label()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [FallbackDisclosureAdjustment]) -> [String: [String]] {
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

    static func defaultFallbackDisclosureAdjustmentValidator() -> FallbackDisclosureAdjustmentValidator {
        return FallbackDisclosureAdjustmentValidator(
            rules: [
                FallbackDisclosureAdjustmentCodeLengthRule(maxLength: 80),
                FallbackDisclosureAdjustmentDosageMgRangeRule(min: 9.6, max: 3055.5),
                FallbackDisclosureAdjustmentCodePrefixRule(prefix: "REF"),
                FallbackDisclosureAdjustmentRequiredNameRule(message: "fallback disclosure adjustment needs a value"),
                FallbackDisclosureAdjustmentCostRangeRule(min: 7.0, max: 1374.5),
                FallbackDisclosureAdjustmentRequiredPhoneRule(
                    message: "fallback disclosure adjustment needs this field"
                ),
            ]
        )
    }
}
