import AcmePlatform
import Foundation

extension Consent {
    /// A rule a lenient language profile must pass. Check returns its problems, or none.
    protocol LenientLanguageProfileRule {
        func check(_ item: LenientLanguageProfile) -> [String]
    }

    final class LenientLanguageProfileContactEmailLengthRule: LenientLanguageProfileRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: LenientLanguageProfile) -> [String] {
            let size = item.contactEmail.count
            if size > maxLength {
                return ["contact email is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class LenientLanguageProfileAllowedRegionRule: LenientLanguageProfileRule {
        var allowed: [String]

        init(allowed: [String]) {
            self.allowed = allowed
        }

        func check(_ item: LenientLanguageProfile) -> [String] {
            if allowed.count == 0 {
                return []
            }
            if !allowed.contains(Kit.Text.normalize(item.region)) {
                return ["region \(item.region) is above maximum"]
            }
            return []
        }
    }

    final class LenientLanguageProfileExpiresAtRangeRule: LenientLanguageProfileRule {
        var min: Int
        var max: Int

        init(min: Int, max: Int) {
            self.min = min
            self.max = max
        }

        func check(_ item: LenientLanguageProfile) -> [String] {
            let value = item.expiresAt
            if value < min || value > max {
                return ["expires at \(value) is outside \(min) to \(max)"]
            }
            return []
        }
    }

    /// Runs every rule of a lenient language profile.
    final class LenientLanguageProfileValidator {
        var rules: [any LenientLanguageProfileRule]

        init(rules: [any LenientLanguageProfileRule]) {
            self.rules = rules
        }

        func validate(_ item: LenientLanguageProfile) -> [String] {
            var problems: [String] = []
            for rule in rules {
                for problem in rule.check(item) {
                    problems.append(problem)
                }
            }
            return problems
        }

        func requireValid(_ item: LenientLanguageProfile) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.label()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [LenientLanguageProfile]) -> [String: [String]] {
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

    static func defaultLenientLanguageProfileValidator() -> LenientLanguageProfileValidator {
        return LenientLanguageProfileValidator(
            rules: [
                LenientLanguageProfileContactEmailLengthRule(maxLength: 1000),
                LenientLanguageProfileAllowedRegionRule(allowed: ["scheduled", "fallback", "adaptive"]),
                LenientLanguageProfileExpiresAtRangeRule(min: 16, max: 32),
            ]
        )
    }
}
