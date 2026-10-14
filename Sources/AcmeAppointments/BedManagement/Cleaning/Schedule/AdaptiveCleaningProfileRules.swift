import AcmePlatform
import Foundation

extension BedManagement {
    /// A rule a adaptive cleaning profile must pass. Check returns its problems, or none.
    protocol AdaptiveCleaningProfileRule {
        func check(_ item: AdaptiveCleaningProfile) -> [String]
    }

    final class AdaptiveCleaningProfileRequiredCodeRule: AdaptiveCleaningProfileRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: AdaptiveCleaningProfile) -> [String] {
            if item.code.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class AdaptiveCleaningProfileAllowedCodeRule: AdaptiveCleaningProfileRule {
        var allowed: [String]

        init(allowed: [String]) {
            self.allowed = allowed
        }

        func check(_ item: AdaptiveCleaningProfile) -> [String] {
            if allowed.count == 0 {
                return []
            }
            if !allowed.contains(Kit.Text.normalize(item.code)) {
                return ["code \(item.code) is blocked"]
            }
            return []
        }
    }

    final class AdaptiveCleaningProfileCodePrefixRule: AdaptiveCleaningProfileRule {
        var prefix: String

        init(prefix: String) {
            self.prefix = prefix
        }

        func check(_ item: AdaptiveCleaningProfile) -> [String] {
            if !item.code.uppercased().hasPrefix(prefix.uppercased()) {
                return ["code must start with \(prefix)"]
            }
            return []
        }
    }

    final class AdaptiveCleaningProfileCurrencyLengthRule: AdaptiveCleaningProfileRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: AdaptiveCleaningProfile) -> [String] {
            let size = item.currency.count
            if size > maxLength {
                return ["currency is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class AdaptiveCleaningProfileQuantityRangeRule: AdaptiveCleaningProfileRule {
        var min: Int
        var max: Int

        init(min: Int, max: Int) {
            self.min = min
            self.max = max
        }

        func check(_ item: AdaptiveCleaningProfile) -> [String] {
            let value = item.quantity
            if value < min || value > max {
                return ["quantity \(value) is outside \(min) to \(max)"]
            }
            return []
        }
    }

    final class AdaptiveCleaningProfileRequiredLabelRule: AdaptiveCleaningProfileRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: AdaptiveCleaningProfile) -> [String] {
            if item.label.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    /// Runs every rule of a adaptive cleaning profile.
    final class AdaptiveCleaningProfileValidator {
        var rules: [any AdaptiveCleaningProfileRule]

        init(rules: [any AdaptiveCleaningProfileRule]) {
            self.rules = rules
        }

        func validate(_ item: AdaptiveCleaningProfile) -> [String] {
            var problems: [String] = []
            for rule in rules {
                for problem in rule.check(item) {
                    problems.append(problem)
                }
            }
            return problems
        }

        func requireValid(_ item: AdaptiveCleaningProfile) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.displayLabel()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [AdaptiveCleaningProfile]) -> [String: [String]] {
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

    static func defaultAdaptiveCleaningProfileValidator() -> AdaptiveCleaningProfileValidator {
        return AdaptiveCleaningProfileValidator(
            rules: [
                AdaptiveCleaningProfileRequiredCodeRule(message: "adaptive cleaning profile needs an entry"),
                AdaptiveCleaningProfileAllowedCodeRule(allowed: ["tiered"]),
                AdaptiveCleaningProfileCodePrefixRule(prefix: "X"),
                AdaptiveCleaningProfileCurrencyLengthRule(maxLength: 1000),
                AdaptiveCleaningProfileQuantityRangeRule(min: 64, max: 1000),
                AdaptiveCleaningProfileRequiredLabelRule(message: "adaptive cleaning profile needs an entry"),
            ]
        )
    }
}
