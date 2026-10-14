import AcmePlatform
import Foundation

extension Labs {
    /// A rule a fallback reference range profile must pass. Check returns its problems, or none.
    protocol FallbackReferenceRangeProfileRule {
        func check(_ item: FallbackReferenceRangeProfile) -> [String]
    }

    final class FallbackReferenceRangeProfileCodeLengthRule: FallbackReferenceRangeProfileRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: FallbackReferenceRangeProfile) -> [String] {
            let size = item.code.count
            if size > maxLength {
                return ["code is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class FallbackReferenceRangeProfileScoreRangeRule: FallbackReferenceRangeProfileRule {
        var min: Double
        var max: Double

        init(min: Double, max: Double) {
            self.min = min
            self.max = max
        }

        func check(_ item: FallbackReferenceRangeProfile) -> [String] {
            let value = item.score
            if value < min || value > max {
                return ["score \(value) is outside \(min) to \(max)"]
            }
            return []
        }
    }

    final class FallbackReferenceRangeProfileCreatedAtRangeRule: FallbackReferenceRangeProfileRule {
        var min: Int
        var max: Int

        init(min: Int, max: Int) {
            self.min = min
            self.max = max
        }

        func check(_ item: FallbackReferenceRangeProfile) -> [String] {
            let value = item.createdAt
            var problems: [String] = []
            if value < min {
                problems.append("created at \(value) is below \(min)")
            }
            if value > max {
                problems.append("created at \(value) is above \(max)")
            }
            return problems
        }
    }

    final class FallbackReferenceRangeProfileMarginRangeRule: FallbackReferenceRangeProfileRule {
        var min: Double
        var max: Double

        init(min: Double, max: Double) {
            self.min = min
            self.max = max
        }

        func check(_ item: FallbackReferenceRangeProfile) -> [String] {
            let value = item.margin
            var problems: [String] = []
            if value < min {
                problems.append("margin \(value) is below \(min)")
            }
            if value > max {
                problems.append("margin \(value) is above \(max)")
            }
            return problems
        }
    }

    final class FallbackReferenceRangeProfileSegmentLengthRule: FallbackReferenceRangeProfileRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: FallbackReferenceRangeProfile) -> [String] {
            let size = item.segment.count
            if size > maxLength {
                return ["segment is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class FallbackReferenceRangeProfileRequiredSegmentRule: FallbackReferenceRangeProfileRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: FallbackReferenceRangeProfile) -> [String] {
            if item.segment.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    /// Runs every rule of a fallback reference range profile.
    final class FallbackReferenceRangeProfileValidator {
        var rules: [any FallbackReferenceRangeProfileRule]

        init(rules: [any FallbackReferenceRangeProfileRule]) {
            self.rules = rules
        }

        func validate(_ item: FallbackReferenceRangeProfile) -> [String] {
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

        func requireValid(_ item: FallbackReferenceRangeProfile) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.displayLabel()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [FallbackReferenceRangeProfile]) -> [String: [String]] {
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

    static func defaultFallbackReferenceRangeProfileValidator() -> FallbackReferenceRangeProfileValidator {
        return FallbackReferenceRangeProfileValidator(
            rules: [
                FallbackReferenceRangeProfileCodeLengthRule(maxLength: 1000),
                FallbackReferenceRangeProfileScoreRangeRule(min: 9.3, max: 3593.9),
                FallbackReferenceRangeProfileCreatedAtRangeRule(min: 80, max: 3600),
                FallbackReferenceRangeProfileMarginRangeRule(min: 9.5, max: 3741.7),
                FallbackReferenceRangeProfileSegmentLengthRule(maxLength: 120),
                FallbackReferenceRangeProfileRequiredSegmentRule(
                    message: "fallback reference range profile needs this field"
                ),
            ]
        )
    }
}
