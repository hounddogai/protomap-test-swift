import AcmePlatform
import Foundation

extension Consent {
    /// A rule a adaptive disclosure exception must pass. Check returns its problems, or none.
    protocol AdaptiveDisclosureExceptionRule {
        func check(_ item: AdaptiveDisclosureException) -> [String]
    }

    final class AdaptiveDisclosureExceptionPayerLengthRule: AdaptiveDisclosureExceptionRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: AdaptiveDisclosureException) -> [String] {
            let size = item.payer.count
            if size > maxLength {
                return ["payer is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class AdaptiveDisclosureExceptionAllowedReviewerRule: AdaptiveDisclosureExceptionRule {
        var allowed: [String]

        init(allowed: [String]) {
            self.allowed = allowed
        }

        func check(_ item: AdaptiveDisclosureException) -> [String] {
            if allowed.count == 0 {
                return []
            }
            if !allowed.contains(Kit.Text.normalize(item.reviewer)) {
                return ["reviewer \(item.reviewer) is not allowed"]
            }
            return []
        }
    }

    final class AdaptiveDisclosureExceptionStartsAtRangeRule: AdaptiveDisclosureExceptionRule {
        var min: Int
        var max: Int

        init(min: Int, max: Int) {
            self.min = min
            self.max = max
        }

        func check(_ item: AdaptiveDisclosureException) -> [String] {
            let value = item.startsAt
            if value < min || value > max {
                return ["starts at \(value) is outside \(min) to \(max)"]
            }
            return []
        }
    }

    /// Runs every rule of a adaptive disclosure exception.
    final class AdaptiveDisclosureExceptionValidator {
        var rules: [any AdaptiveDisclosureExceptionRule]

        init(rules: [any AdaptiveDisclosureExceptionRule]) {
            self.rules = rules
        }

        func validate(_ item: AdaptiveDisclosureException) -> [String] {
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

        func requireValid(_ item: AdaptiveDisclosureException) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.label()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [AdaptiveDisclosureException]) -> [String: [String]] {
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

    static func defaultAdaptiveDisclosureExceptionValidator() -> AdaptiveDisclosureExceptionValidator {
        return AdaptiveDisclosureExceptionValidator(
            rules: [
                AdaptiveDisclosureExceptionPayerLengthRule(maxLength: 120),
                AdaptiveDisclosureExceptionAllowedReviewerRule(allowed: ["batched"]),
                AdaptiveDisclosureExceptionStartsAtRangeRule(min: 80, max: 255),
            ]
        )
    }
}
