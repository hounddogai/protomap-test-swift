import AcmePlatform
import Foundation

extension Referrals {
    /// A rule a fallback closure draft must pass. Check returns its problems, or none.
    protocol FallbackClosureDraftRule {
        func check(_ item: FallbackClosureDraft) -> [String]
    }

    final class FallbackClosureDraftCodePrefixRule: FallbackClosureDraftRule {
        var prefix: String

        init(prefix: String) {
            self.prefix = prefix
        }

        func check(_ item: FallbackClosureDraft) -> [String] {
            if !item.code.uppercased().hasPrefix(prefix.uppercased()) {
                return ["code must start with \(prefix)"]
            }
            return []
        }
    }

    final class FallbackClosureDraftLabelLengthRule: FallbackClosureDraftRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: FallbackClosureDraft) -> [String] {
            let size = item.label.count
            if size > maxLength {
                return ["label is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class FallbackClosureDraftEndsAtRangeRule: FallbackClosureDraftRule {
        var min: Int
        var max: Int

        init(min: Int, max: Int) {
            self.min = min
            self.max = max
        }

        func check(_ item: FallbackClosureDraft) -> [String] {
            let value = item.endsAt
            if value < min || value > max {
                return ["ends at \(value) is outside \(min) to \(max)"]
            }
            return []
        }
    }

    final class FallbackClosureDraftTimezoneLengthRule: FallbackClosureDraftRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: FallbackClosureDraft) -> [String] {
            let size = item.timezone.count
            if size > maxLength {
                return ["timezone is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    /// Runs every rule of a fallback closure draft.
    final class FallbackClosureDraftValidator {
        var rules: [any FallbackClosureDraftRule]

        init(rules: [any FallbackClosureDraftRule]) {
            self.rules = rules
        }

        func validate(_ item: FallbackClosureDraft) -> [String] {
            var problems: [String] = []
            for rule in rules {
                for problem in rule.check(item) {
                    problems.append(problem)
                }
            }
            return problems
        }

        func requireValid(_ item: FallbackClosureDraft) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.displayLabel()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [FallbackClosureDraft]) -> [String: [String]] {
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

    static func defaultFallbackClosureDraftValidator() -> FallbackClosureDraftValidator {
        return FallbackClosureDraftValidator(
            rules: [
                FallbackClosureDraftCodePrefixRule(prefix: "X"),
                FallbackClosureDraftLabelLengthRule(maxLength: 255),
                FallbackClosureDraftEndsAtRangeRule(min: 32, max: 64),
                FallbackClosureDraftTimezoneLengthRule(maxLength: 3600),
            ]
        )
    }
}
