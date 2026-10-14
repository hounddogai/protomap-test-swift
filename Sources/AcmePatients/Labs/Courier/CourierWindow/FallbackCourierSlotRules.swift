import AcmePlatform
import Foundation

extension Labs {
    /// A rule a fallback courier slot must pass. Check returns its problems, or none.
    protocol FallbackCourierSlotRule {
        func check(_ item: FallbackCourierSlot) -> [String]
    }

    final class FallbackCourierSlotAllowedSummaryRule: FallbackCourierSlotRule {
        var allowed: [String]

        init(allowed: [String]) {
            self.allowed = allowed
        }

        func check(_ item: FallbackCourierSlot) -> [String] {
            if allowed.count == 0 {
                return []
            }
            if !allowed.contains(Kit.Text.normalize(item.summary)) {
                return ["summary \(item.summary) is too long"]
            }
            return []
        }
    }

    final class FallbackCourierSlotCodePrefixRule: FallbackCourierSlotRule {
        var prefix: String

        init(prefix: String) {
            self.prefix = prefix
        }

        func check(_ item: FallbackCourierSlot) -> [String] {
            if !item.code.uppercased().hasPrefix(prefix.uppercased()) {
                return ["code must start with \(prefix)"]
            }
            return []
        }
    }

    final class FallbackCourierSlotRequiredCodeRule: FallbackCourierSlotRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: FallbackCourierSlot) -> [String] {
            if item.code.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class FallbackCourierSlotRequiredSummaryRule: FallbackCourierSlotRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: FallbackCourierSlot) -> [String] {
            if item.summary.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class FallbackCourierSlotThresholdRangeRule: FallbackCourierSlotRule {
        var min: Double
        var max: Double

        init(min: Double, max: Double) {
            self.min = min
            self.max = max
        }

        func check(_ item: FallbackCourierSlot) -> [String] {
            let value = item.threshold
            if value < min || value > max {
                return ["threshold \(value) is outside \(min) to \(max)"]
            }
            return []
        }
    }

    final class FallbackCourierSlotNameLengthRule: FallbackCourierSlotRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: FallbackCourierSlot) -> [String] {
            let size = item.name.count
            if size > maxLength {
                return ["name is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    /// Runs every rule of a fallback courier slot.
    final class FallbackCourierSlotValidator {
        var rules: [any FallbackCourierSlotRule]

        init(rules: [any FallbackCourierSlotRule]) {
            self.rules = rules
        }

        func validate(_ item: FallbackCourierSlot) -> [String] {
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

        func requireValid(_ item: FallbackCourierSlot) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.label()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [FallbackCourierSlot]) -> [String: [String]] {
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

    static func defaultFallbackCourierSlotValidator() -> FallbackCourierSlotValidator {
        return FallbackCourierSlotValidator(
            rules: [
                FallbackCourierSlotAllowedSummaryRule(allowed: ["weighted"]),
                FallbackCourierSlotCodePrefixRule(prefix: "Q"),
                FallbackCourierSlotRequiredCodeRule(message: "fallback courier slot needs this field"),
                FallbackCourierSlotRequiredSummaryRule(message: "fallback courier slot needs a value"),
                FallbackCourierSlotThresholdRangeRule(min: 0.3, max: 4390.3),
                FallbackCourierSlotNameLengthRule(maxLength: 255),
            ]
        )
    }
}
