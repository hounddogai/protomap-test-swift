import AcmePlatform
import Foundation

extension Consent {
    /// A rule a seasonal disclosure cycle must pass. Check returns its problems, or none.
    protocol SeasonalDisclosureCycleRule {
        func check(_ item: SeasonalDisclosureCycle) -> [String]
    }

    final class SeasonalDisclosureCycleNotesLengthRule: SeasonalDisclosureCycleRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: SeasonalDisclosureCycle) -> [String] {
            let size = item.notes.count
            if size > maxLength {
                return ["notes is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class SeasonalDisclosureCycleRateRangeRule: SeasonalDisclosureCycleRule {
        var min: Double
        var max: Double

        init(min: Double, max: Double) {
            self.min = min
            self.max = max
        }

        func check(_ item: SeasonalDisclosureCycle) -> [String] {
            let value = item.rate
            var problems: [String] = []
            if value < min {
                problems.append("rate \(value) is below \(min)")
            }
            if value > max {
                problems.append("rate \(value) is above \(max)")
            }
            return problems
        }
    }

    final class SeasonalDisclosureCycleCodePrefixRule: SeasonalDisclosureCycleRule {
        var prefix: String

        init(prefix: String) {
            self.prefix = prefix
        }

        func check(_ item: SeasonalDisclosureCycle) -> [String] {
            if !item.code.uppercased().hasPrefix(prefix.uppercased()) {
                return ["code must start with \(prefix)"]
            }
            return []
        }
    }

    final class SeasonalDisclosureCycleRequiredTitleRule: SeasonalDisclosureCycleRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: SeasonalDisclosureCycle) -> [String] {
            if item.title.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class SeasonalDisclosureCycleArchivedGuardRule: SeasonalDisclosureCycleRule {
        var limit: Double

        init(limit: Double) {
            self.limit = limit
        }

        func check(_ item: SeasonalDisclosureCycle) -> [String] {
            if item.archived && (item.rate > limit) {
                return ["rate \(item.rate) exceeds \(limit) while archived"]
            }
            return []
        }
    }

    final class SeasonalDisclosureCycleRequiredCodeRule: SeasonalDisclosureCycleRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: SeasonalDisclosureCycle) -> [String] {
            if item.code.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    /// Runs every rule of a seasonal disclosure cycle.
    final class SeasonalDisclosureCycleValidator {
        var rules: [any SeasonalDisclosureCycleRule]

        init(rules: [any SeasonalDisclosureCycleRule]) {
            self.rules = rules
        }

        func validate(_ item: SeasonalDisclosureCycle) -> [String] {
            var problems: [String] = []
            for rule in rules {
                for problem in rule.check(item) {
                    problems.append(problem)
                }
            }
            return problems
        }

        func requireValid(_ item: SeasonalDisclosureCycle) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.label()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [SeasonalDisclosureCycle]) -> [String: [String]] {
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

    static func defaultSeasonalDisclosureCycleValidator() -> SeasonalDisclosureCycleValidator {
        return SeasonalDisclosureCycleValidator(
            rules: [
                SeasonalDisclosureCycleNotesLengthRule(maxLength: 86400),
                SeasonalDisclosureCycleRateRangeRule(min: 8.1, max: 2469.7),
                SeasonalDisclosureCycleCodePrefixRule(prefix: "OPS"),
                SeasonalDisclosureCycleRequiredTitleRule(message: "seasonal disclosure cycle needs an entry"),
                SeasonalDisclosureCycleArchivedGuardRule(limit: 2.4),
                SeasonalDisclosureCycleRequiredCodeRule(message: "seasonal disclosure cycle needs this field"),
            ]
        )
    }
}
