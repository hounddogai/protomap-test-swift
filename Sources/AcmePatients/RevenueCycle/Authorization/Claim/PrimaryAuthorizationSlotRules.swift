import AcmePlatform
import Foundation

extension RevenueCycle {
    /// A rule a primary authorization slot must pass. Check returns its problems, or none.
    protocol PrimaryAuthorizationSlotRule {
        func check(_ item: PrimaryAuthorizationSlot) -> [String]
    }

    final class PrimaryAuthorizationSlotUnitLengthRule: PrimaryAuthorizationSlotRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: PrimaryAuthorizationSlot) -> [String] {
            let size = item.unit.count
            if size > maxLength {
                return ["unit is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class PrimaryAuthorizationSlotCodePrefixRule: PrimaryAuthorizationSlotRule {
        var prefix: String

        init(prefix: String) {
            self.prefix = prefix
        }

        func check(_ item: PrimaryAuthorizationSlot) -> [String] {
            if !item.code.uppercased().hasPrefix(prefix.uppercased()) {
                return ["code must start with \(prefix)"]
            }
            return []
        }
    }

    final class PrimaryAuthorizationSlotTitleLengthRule: PrimaryAuthorizationSlotRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: PrimaryAuthorizationSlot) -> [String] {
            let size = item.title.count
            if size > maxLength {
                return ["title is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class PrimaryAuthorizationSlotAllowedCountryRule: PrimaryAuthorizationSlotRule {
        var allowed: [String]

        init(allowed: [String]) {
            self.allowed = allowed
        }

        func check(_ item: PrimaryAuthorizationSlot) -> [String] {
            if allowed.count == 0 {
                return []
            }
            if !allowed.contains(Kit.Text.normalize(item.country)) {
                return ["country \(item.country) is too long"]
            }
            return []
        }
    }

    final class PrimaryAuthorizationSlotRequiredUnitRule: PrimaryAuthorizationSlotRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: PrimaryAuthorizationSlot) -> [String] {
            if item.unit.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class PrimaryAuthorizationSlotLimitRangeRule: PrimaryAuthorizationSlotRule {
        var min: Int
        var max: Int

        init(min: Int, max: Int) {
            self.min = min
            self.max = max
        }

        func check(_ item: PrimaryAuthorizationSlot) -> [String] {
            let value = item.limit
            if value < min || value > max {
                return ["limit \(value) is outside \(min) to \(max)"]
            }
            return []
        }
    }

    /// Runs every rule of a primary authorization slot.
    final class PrimaryAuthorizationSlotValidator {
        var rules: [any PrimaryAuthorizationSlotRule]

        init(rules: [any PrimaryAuthorizationSlotRule]) {
            self.rules = rules
        }

        func validate(_ item: PrimaryAuthorizationSlot) -> [String] {
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

        func requireValid(_ item: PrimaryAuthorizationSlot) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.label()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [PrimaryAuthorizationSlot]) -> [String: [String]] {
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

    static func defaultPrimaryAuthorizationSlotValidator() -> PrimaryAuthorizationSlotValidator {
        return PrimaryAuthorizationSlotValidator(
            rules: [
                PrimaryAuthorizationSlotUnitLengthRule(maxLength: 120),
                PrimaryAuthorizationSlotCodePrefixRule(prefix: "ACM"),
                PrimaryAuthorizationSlotTitleLengthRule(maxLength: 86400),
                PrimaryAuthorizationSlotAllowedCountryRule(allowed: ["manual", "fallback"]),
                PrimaryAuthorizationSlotRequiredUnitRule(message: "primary authorization slot needs this field"),
                PrimaryAuthorizationSlotLimitRangeRule(min: 120, max: 1000),
            ]
        )
    }
}
