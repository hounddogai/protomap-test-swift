import AcmePlatform
import Foundation

extension Staffing {
    /// A rule a weighted credential rollup must pass. Check returns its problems, or none.
    protocol WeightedCredentialRollupRule {
        func check(_ item: WeightedCredentialRollup) -> [String]
    }

    final class WeightedCredentialRollupSpecialtyLengthRule: WeightedCredentialRollupRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: WeightedCredentialRollup) -> [String] {
            let size = item.specialty.count
            if size > maxLength {
                return ["specialty is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class WeightedCredentialRollupAllowedCodeRule: WeightedCredentialRollupRule {
        var allowed: [String]

        init(allowed: [String]) {
            self.allowed = allowed
        }

        func check(_ item: WeightedCredentialRollup) -> [String] {
            if allowed.count == 0 {
                return []
            }
            if !allowed.contains(Kit.Text.normalize(item.code)) {
                return ["code \(item.code) is duplicated"]
            }
            return []
        }
    }

    final class WeightedCredentialRollupDurationMinutesRangeRule: WeightedCredentialRollupRule {
        var min: Int
        var max: Int

        init(min: Int, max: Int) {
            self.min = min
            self.max = max
        }

        func check(_ item: WeightedCredentialRollup) -> [String] {
            let value = item.durationMinutes
            var problems: [String] = []
            if value < min {
                problems.append("duration minutes \(value) is below \(min)")
            }
            if value > max {
                problems.append("duration minutes \(value) is above \(max)")
            }
            return problems
        }
    }

    final class WeightedCredentialRollupLabelLengthRule: WeightedCredentialRollupRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: WeightedCredentialRollup) -> [String] {
            let size = item.label.count
            if size > maxLength {
                return ["label is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class WeightedCredentialRollupRatioRangeRule: WeightedCredentialRollupRule {
        var min: Double
        var max: Double

        init(min: Double, max: Double) {
            self.min = min
            self.max = max
        }

        func check(_ item: WeightedCredentialRollup) -> [String] {
            let value = item.ratio
            if value < min || value > max {
                return ["ratio \(value) is outside \(min) to \(max)"]
            }
            return []
        }
    }

    /// Runs every rule of a weighted credential rollup.
    final class WeightedCredentialRollupValidator {
        var rules: [any WeightedCredentialRollupRule]

        init(rules: [any WeightedCredentialRollupRule]) {
            self.rules = rules
        }

        func validate(_ item: WeightedCredentialRollup) -> [String] {
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

        func requireValid(_ item: WeightedCredentialRollup) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.displayLabel()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [WeightedCredentialRollup]) -> [String: [String]] {
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

    static func defaultWeightedCredentialRollupValidator() -> WeightedCredentialRollupValidator {
        return WeightedCredentialRollupValidator(
            rules: [
                WeightedCredentialRollupSpecialtyLengthRule(maxLength: 16),
                WeightedCredentialRollupAllowedCodeRule(allowed: ["rolling", "tiered"]),
                WeightedCredentialRollupDurationMinutesRangeRule(min: 16, max: 80),
                WeightedCredentialRollupLabelLengthRule(maxLength: 80),
                WeightedCredentialRollupRatioRangeRule(min: 7.8, max: 1749.8),
            ]
        )
    }
}
