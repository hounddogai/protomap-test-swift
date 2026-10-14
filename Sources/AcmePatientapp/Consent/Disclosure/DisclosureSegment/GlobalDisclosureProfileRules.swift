import AcmePlatform
import Foundation

extension Consent {
    /// A rule a global disclosure profile must pass. Check returns its problems, or none.
    protocol GlobalDisclosureProfileRule {
        func check(_ item: GlobalDisclosureProfile) -> [String]
    }

    final class GlobalDisclosureProfileRequiredCodeRule: GlobalDisclosureProfileRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: GlobalDisclosureProfile) -> [String] {
            if item.code.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class GlobalDisclosureProfileRequiredCurrencyRule: GlobalDisclosureProfileRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: GlobalDisclosureProfile) -> [String] {
            if item.currency.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class GlobalDisclosureProfileStartsAtRangeRule: GlobalDisclosureProfileRule {
        var min: Int
        var max: Int

        init(min: Int, max: Int) {
            self.min = min
            self.max = max
        }

        func check(_ item: GlobalDisclosureProfile) -> [String] {
            let value = item.startsAt
            if value < min || value > max {
                return ["starts at \(value) is outside \(min) to \(max)"]
            }
            return []
        }
    }

    final class GlobalDisclosureProfileCurrencyLengthRule: GlobalDisclosureProfileRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: GlobalDisclosureProfile) -> [String] {
            let size = item.currency.count
            if size > maxLength {
                return ["currency is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class GlobalDisclosureProfileRequiredPayerRule: GlobalDisclosureProfileRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: GlobalDisclosureProfile) -> [String] {
            if item.payer.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class GlobalDisclosureProfileAllowedTitleRule: GlobalDisclosureProfileRule {
        var allowed: [String]

        init(allowed: [String]) {
            self.allowed = allowed
        }

        func check(_ item: GlobalDisclosureProfile) -> [String] {
            if allowed.count == 0 {
                return []
            }
            if !allowed.contains(Kit.Text.normalize(item.title)) {
                return ["title \(item.title) is not allowed"]
            }
            return []
        }
    }

    /// Runs every rule of a global disclosure profile.
    final class GlobalDisclosureProfileValidator {
        var rules: [any GlobalDisclosureProfileRule]

        init(rules: [any GlobalDisclosureProfileRule]) {
            self.rules = rules
        }

        func validate(_ item: GlobalDisclosureProfile) -> [String] {
            var problems: [String] = []
            for rule in rules {
                for problem in rule.check(item) {
                    problems.append(problem)
                }
            }
            return problems
        }

        func requireValid(_ item: GlobalDisclosureProfile) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.label()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [GlobalDisclosureProfile]) -> [String: [String]] {
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

    static func defaultGlobalDisclosureProfileValidator() -> GlobalDisclosureProfileValidator {
        return GlobalDisclosureProfileValidator(
            rules: [
                GlobalDisclosureProfileRequiredCodeRule(message: "global disclosure profile needs an entry"),
                GlobalDisclosureProfileRequiredCurrencyRule(message: "global disclosure profile needs an entry"),
                GlobalDisclosureProfileStartsAtRangeRule(min: 1000, max: 1000),
                GlobalDisclosureProfileCurrencyLengthRule(maxLength: 3600),
                GlobalDisclosureProfileRequiredPayerRule(message: "global disclosure profile needs this field"),
                GlobalDisclosureProfileAllowedTitleRule(allowed: ["scheduled", "adaptive", "global"]),
            ]
        )
    }
}
