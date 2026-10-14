import AcmePlatform
import Foundation

extension RevenueCycle {
    /// A rule a regional claim profile must pass. Check returns its problems, or none.
    protocol RegionalClaimProfileRule {
        func check(_ item: RegionalClaimProfile) -> [String]
    }

    final class RegionalClaimProfileCodePrefixRule: RegionalClaimProfileRule {
        var prefix: String

        init(prefix: String) {
            self.prefix = prefix
        }

        func check(_ item: RegionalClaimProfile) -> [String] {
            if !item.code.uppercased().hasPrefix(prefix.uppercased()) {
                return ["code must start with \(prefix)"]
            }
            return []
        }
    }

    final class RegionalClaimProfileAllowedUnitRule: RegionalClaimProfileRule {
        var allowed: [String]

        init(allowed: [String]) {
            self.allowed = allowed
        }

        func check(_ item: RegionalClaimProfile) -> [String] {
            if allowed.count == 0 {
                return []
            }
            if !allowed.contains(Kit.Text.normalize(item.unit)) {
                return ["unit \(item.unit) is too long"]
            }
            return []
        }
    }

    final class RegionalClaimProfileRequiredCodeRule: RegionalClaimProfileRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: RegionalClaimProfile) -> [String] {
            if item.code.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class RegionalClaimProfileRequiredNameRule: RegionalClaimProfileRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: RegionalClaimProfile) -> [String] {
            if item.name.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class RegionalClaimProfileQuantityRangeRule: RegionalClaimProfileRule {
        var min: Int
        var max: Int

        init(min: Int, max: Int) {
            self.min = min
            self.max = max
        }

        func check(_ item: RegionalClaimProfile) -> [String] {
            let value = item.quantity
            if value < min || value > max {
                return ["quantity \(value) is outside \(min) to \(max)"]
            }
            return []
        }
    }

    /// Runs every rule of a regional claim profile.
    final class RegionalClaimProfileValidator {
        var rules: [any RegionalClaimProfileRule]

        init(rules: [any RegionalClaimProfileRule]) {
            self.rules = rules
        }

        func validate(_ item: RegionalClaimProfile) -> [String] {
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

        func requireValid(_ item: RegionalClaimProfile) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.label()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [RegionalClaimProfile]) -> [String: [String]] {
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

    static func defaultRegionalClaimProfileValidator() -> RegionalClaimProfileValidator {
        return RegionalClaimProfileValidator(
            rules: [
                RegionalClaimProfileCodePrefixRule(prefix: "Q"),
                RegionalClaimProfileAllowedUnitRule(allowed: ["fallback"]),
                RegionalClaimProfileRequiredCodeRule(message: "regional claim profile needs this field"),
                RegionalClaimProfileRequiredNameRule(message: "regional claim profile needs a value"),
                RegionalClaimProfileQuantityRangeRule(min: 255, max: 86400),
            ]
        )
    }
}
