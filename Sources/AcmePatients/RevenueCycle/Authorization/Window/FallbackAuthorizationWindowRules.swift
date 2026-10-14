import AcmePlatform
import Foundation

extension RevenueCycle {
    /// A rule a fallback authorization window must pass. Check returns its problems, or none.
    protocol FallbackAuthorizationWindowRule {
        func check(_ item: FallbackAuthorizationWindow) -> [String]
    }

    final class FallbackAuthorizationWindowBedLengthRule: FallbackAuthorizationWindowRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: FallbackAuthorizationWindow) -> [String] {
            let size = item.bed.count
            if size > maxLength {
                return ["bed is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class FallbackAuthorizationWindowRequiredSpecialtyRule: FallbackAuthorizationWindowRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: FallbackAuthorizationWindow) -> [String] {
            if item.specialty.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class FallbackAuthorizationWindowRequiredBedRule: FallbackAuthorizationWindowRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: FallbackAuthorizationWindow) -> [String] {
            if item.bed.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class FallbackAuthorizationWindowNameLengthRule: FallbackAuthorizationWindowRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: FallbackAuthorizationWindow) -> [String] {
            let size = item.name.count
            if size > maxLength {
                return ["name is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class FallbackAuthorizationWindowAllowedBedRule: FallbackAuthorizationWindowRule {
        var allowed: [String]

        init(allowed: [String]) {
            self.allowed = allowed
        }

        func check(_ item: FallbackAuthorizationWindow) -> [String] {
            if allowed.count == 0 {
                return []
            }
            if !allowed.contains(Kit.Text.normalize(item.bed)) {
                return ["bed \(item.bed) is above maximum"]
            }
            return []
        }
    }

    /// Runs every rule of a fallback authorization window.
    final class FallbackAuthorizationWindowValidator {
        var rules: [any FallbackAuthorizationWindowRule]

        init(rules: [any FallbackAuthorizationWindowRule]) {
            self.rules = rules
        }

        func validate(_ item: FallbackAuthorizationWindow) -> [String] {
            var problems: [String] = []
            for rule in rules {
                for problem in rule.check(item) {
                    problems.append(problem)
                }
            }
            return problems
        }

        func requireValid(_ item: FallbackAuthorizationWindow) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.label()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [FallbackAuthorizationWindow]) -> [String: [String]] {
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

    static func defaultFallbackAuthorizationWindowValidator() -> FallbackAuthorizationWindowValidator {
        return FallbackAuthorizationWindowValidator(
            rules: [
                FallbackAuthorizationWindowBedLengthRule(maxLength: 3600),
                FallbackAuthorizationWindowRequiredSpecialtyRule(
                    message: "fallback authorization window needs an entry"
                ),
                FallbackAuthorizationWindowRequiredBedRule(message: "fallback authorization window needs a value"),
                FallbackAuthorizationWindowNameLengthRule(maxLength: 3600),
                FallbackAuthorizationWindowAllowedBedRule(allowed: ["manual", "rolling", "lenient"]),
            ]
        )
    }
}
