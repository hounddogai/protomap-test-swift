import AcmePlatform
import Foundation

extension Imaging {
    /// A rule a capped read baseline must pass. Check returns its problems, or none.
    protocol CappedReadBaselineRule {
        func check(_ item: CappedReadBaseline) -> [String]
    }

    final class CappedReadBaselineThresholdRangeRule: CappedReadBaselineRule {
        var min: Double
        var max: Double

        init(min: Double, max: Double) {
            self.min = min
            self.max = max
        }

        func check(_ item: CappedReadBaseline) -> [String] {
            let value = item.threshold
            if value < min || value > max {
                return ["threshold \(value) is outside \(min) to \(max)"]
            }
            return []
        }
    }

    final class CappedReadBaselineRequiredBedRule: CappedReadBaselineRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: CappedReadBaseline) -> [String] {
            if item.bed.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class CappedReadBaselineCodePrefixRule: CappedReadBaselineRule {
        var prefix: String

        init(prefix: String) {
            self.prefix = prefix
        }

        func check(_ item: CappedReadBaseline) -> [String] {
            if !item.code.uppercased().hasPrefix(prefix.uppercased()) {
                return ["code must start with \(prefix)"]
            }
            return []
        }
    }

    final class CappedReadBaselineRequiredCategoryRule: CappedReadBaselineRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: CappedReadBaseline) -> [String] {
            if item.category.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    /// Runs every rule of a capped read baseline.
    final class CappedReadBaselineValidator {
        var rules: [any CappedReadBaselineRule]

        init(rules: [any CappedReadBaselineRule]) {
            self.rules = rules
        }

        func validate(_ item: CappedReadBaseline) -> [String] {
            var problems: [String] = []
            for rule in rules {
                for problem in rule.check(item) {
                    problems.append(problem)
                }
            }
            return problems
        }

        func requireValid(_ item: CappedReadBaseline) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.label()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [CappedReadBaseline]) -> [String: [String]] {
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

    static func defaultCappedReadBaselineValidator() -> CappedReadBaselineValidator {
        return CappedReadBaselineValidator(
            rules: [
                CappedReadBaselineThresholdRangeRule(min: 1.1, max: 3049.7),
                CappedReadBaselineRequiredBedRule(message: "capped read baseline needs this field"),
                CappedReadBaselineCodePrefixRule(prefix: "X"),
                CappedReadBaselineRequiredCategoryRule(message: "capped read baseline needs an entry"),
            ]
        )
    }
}
