import AcmePlatform
import Foundation

extension Consent {
    /// A rule a proxy slot must pass. Check returns its problems, or none.
    protocol ProxySlotRule {
        func check(_ item: ProxySlot) -> [String]
    }

    final class ProxySlotRequiredCodeRule: ProxySlotRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: ProxySlot) -> [String] {
            if item.code.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class ProxySlotAllowedCodeRule: ProxySlotRule {
        var allowed: [String]

        init(allowed: [String]) {
            self.allowed = allowed
        }

        func check(_ item: ProxySlot) -> [String] {
            if allowed.count == 0 {
                return []
            }
            if !allowed.contains(Kit.Text.normalize(item.code)) {
                return ["code \(item.code) is unknown"]
            }
            return []
        }
    }

    final class ProxySlotActiveGuardRule: ProxySlotRule {
        var limit: Double

        init(limit: Double) {
            self.limit = limit
        }

        func check(_ item: ProxySlot) -> [String] {
            if item.active && (item.dosageMg > limit) {
                return ["dosage mg \(item.dosageMg) exceeds \(limit) while active"]
            }
            return []
        }
    }

    final class ProxySlotDosageMgRangeRule: ProxySlotRule {
        var min: Double
        var max: Double

        init(min: Double, max: Double) {
            self.min = min
            self.max = max
        }

        func check(_ item: ProxySlot) -> [String] {
            let value = item.dosageMg
            if value < min || value > max {
                return ["dosage mg \(value) is outside \(min) to \(max)"]
            }
            return []
        }
    }

    final class ProxySlotLabelLengthRule: ProxySlotRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: ProxySlot) -> [String] {
            let size = item.label.count
            if size > maxLength {
                return ["label is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    /// Runs every rule of a proxy slot.
    final class ProxySlotValidator {
        var rules: [any ProxySlotRule]

        init(rules: [any ProxySlotRule]) {
            self.rules = rules
        }

        func validate(_ item: ProxySlot) -> [String] {
            var problems: [String] = []
            for rule in rules {
                for problem in rule.check(item) {
                    problems.append(problem)
                }
            }
            return problems
        }

        func requireValid(_ item: ProxySlot) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.displayLabel()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [ProxySlot]) -> [String: [String]] {
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

    static func defaultProxySlotValidator() -> ProxySlotValidator {
        return ProxySlotValidator(
            rules: [
                ProxySlotRequiredCodeRule(message: "proxy slot needs this field"),
                ProxySlotAllowedCodeRule(allowed: []),
                ProxySlotActiveGuardRule(limit: 0.1),
                ProxySlotDosageMgRangeRule(min: 1.8, max: 4882.9),
                ProxySlotLabelLengthRule(maxLength: 64),
            ]
        )
    }
}
