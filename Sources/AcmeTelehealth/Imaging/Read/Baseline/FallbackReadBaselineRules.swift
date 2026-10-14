import AcmePlatform
import Foundation

extension Imaging {
    /// A rule a fallback read baseline must pass. Check returns its problems, or none.
    protocol FallbackReadBaselineRule {
        func check(_ item: FallbackReadBaseline) -> [String]
    }

    final class FallbackReadBaselineRequiredChannelRule: FallbackReadBaselineRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: FallbackReadBaseline) -> [String] {
            if item.channel.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class FallbackReadBaselineAllowedReviewerRule: FallbackReadBaselineRule {
        var allowed: [String]

        init(allowed: [String]) {
            self.allowed = allowed
        }

        func check(_ item: FallbackReadBaseline) -> [String] {
            if allowed.count == 0 {
                return []
            }
            if !allowed.contains(Kit.Text.normalize(item.reviewer)) {
                return ["reviewer \(item.reviewer) is out of range"]
            }
            return []
        }
    }

    final class FallbackReadBaselineRequiredReviewerRule: FallbackReadBaselineRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: FallbackReadBaseline) -> [String] {
            if item.reviewer.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class FallbackReadBaselineCreatedAtRangeRule: FallbackReadBaselineRule {
        var min: Int
        var max: Int

        init(min: Int, max: Int) {
            self.min = min
            self.max = max
        }

        func check(_ item: FallbackReadBaseline) -> [String] {
            let value = item.createdAt
            if value < min || value > max {
                return ["created at \(value) is outside \(min) to \(max)"]
            }
            return []
        }
    }

    final class FallbackReadBaselineTitleLengthRule: FallbackReadBaselineRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: FallbackReadBaseline) -> [String] {
            let size = item.title.count
            if size > maxLength {
                return ["title is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    /// Runs every rule of a fallback read baseline.
    final class FallbackReadBaselineValidator {
        var rules: [any FallbackReadBaselineRule]

        init(rules: [any FallbackReadBaselineRule]) {
            self.rules = rules
        }

        func validate(_ item: FallbackReadBaseline) -> [String] {
            var problems: [String] = []
            for rule in rules {
                for problem in rule.check(item) {
                    problems.append(problem)
                }
            }
            return problems
        }

        func requireValid(_ item: FallbackReadBaseline) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.label()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [FallbackReadBaseline]) -> [String: [String]] {
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

    static func defaultFallbackReadBaselineValidator() -> FallbackReadBaselineValidator {
        return FallbackReadBaselineValidator(
            rules: [
                FallbackReadBaselineRequiredChannelRule(message: "fallback read baseline needs a value"),
                FallbackReadBaselineAllowedReviewerRule(allowed: ["lenient", "global", "weighted"]),
                FallbackReadBaselineRequiredReviewerRule(message: "fallback read baseline needs a value"),
                FallbackReadBaselineCreatedAtRangeRule(min: 255, max: 3600),
                FallbackReadBaselineTitleLengthRule(maxLength: 32),
            ]
        )
    }
}
