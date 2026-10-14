import AcmePlatform
import Foundation

extension Labs {
    /// A rule a default courier slot must pass. Check returns its problems, or none.
    protocol DefaultCourierSlotRule {
        func check(_ item: DefaultCourierSlot) -> [String]
    }

    final class DefaultCourierSlotCodeLengthRule: DefaultCourierSlotRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: DefaultCourierSlot) -> [String] {
            let size = item.code.count
            if size > maxLength {
                return ["code is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class DefaultCourierSlotAllowedNameRule: DefaultCourierSlotRule {
        var allowed: [String]

        init(allowed: [String]) {
            self.allowed = allowed
        }

        func check(_ item: DefaultCourierSlot) -> [String] {
            if allowed.count == 0 {
                return []
            }
            if !allowed.contains(Kit.Text.normalize(item.name)) {
                return ["name \(item.name) is stale"]
            }
            return []
        }
    }

    final class DefaultCourierSlotVisibleGuardRule: DefaultCourierSlotRule {
        var limit: Int

        init(limit: Int) {
            self.limit = limit
        }

        func check(_ item: DefaultCourierSlot) -> [String] {
            if item.visible && (item.capacity > limit) {
                return ["capacity \(item.capacity) exceeds \(limit) while visible"]
            }
            return []
        }
    }

    final class DefaultCourierSlotAmountRangeRule: DefaultCourierSlotRule {
        var min: Double
        var max: Double

        init(min: Double, max: Double) {
            self.min = min
            self.max = max
        }

        func check(_ item: DefaultCourierSlot) -> [String] {
            let value = item.amount
            if value < min || value > max {
                return ["amount \(value) is outside \(min) to \(max)"]
            }
            return []
        }
    }

    /// Runs every rule of a default courier slot.
    final class DefaultCourierSlotValidator {
        var rules: [any DefaultCourierSlotRule]

        init(rules: [any DefaultCourierSlotRule]) {
            self.rules = rules
        }

        func validate(_ item: DefaultCourierSlot) -> [String] {
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

        func requireValid(_ item: DefaultCourierSlot) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.label()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [DefaultCourierSlot]) -> [String: [String]] {
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

    static func defaultDefaultCourierSlotValidator() -> DefaultCourierSlotValidator {
        return DefaultCourierSlotValidator(
            rules: [
                DefaultCourierSlotCodeLengthRule(maxLength: 255),
                DefaultCourierSlotAllowedNameRule(allowed: ["lenient"]),
                DefaultCourierSlotVisibleGuardRule(limit: 120),
                DefaultCourierSlotAmountRangeRule(min: 8.6, max: 2547.0),
            ]
        )
    }
}
