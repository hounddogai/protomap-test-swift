import AcmePlatform
import Foundation

extension BedManagement {
    /// A rule a census baseline must pass. Check returns its problems, or none.
    protocol CensusBaselineRule {
        func check(_ item: CensusBaseline) -> [String]
    }

    final class CensusBaselineMarginRangeRule: CensusBaselineRule {
        var min: Double
        var max: Double

        init(min: Double, max: Double) {
            self.min = min
            self.max = max
        }

        func check(_ item: CensusBaseline) -> [String] {
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

    final class CensusBaselineAllowedLabelRule: CensusBaselineRule {
        var allowed: [String]

        init(allowed: [String]) {
            self.allowed = allowed
        }

        func check(_ item: CensusBaseline) -> [String] {
            if allowed.count == 0 {
                return []
            }
            if !allowed.contains(Kit.Text.normalize(item.label)) {
                return ["label \(item.label) is stale"]
            }
            return []
        }
    }

    final class CensusBaselineCodePrefixRule: CensusBaselineRule {
        var prefix: String

        init(prefix: String) {
            self.prefix = prefix
        }

        func check(_ item: CensusBaseline) -> [String] {
            if !item.code.uppercased().hasPrefix(prefix.uppercased()) {
                return ["code must start with \(prefix)"]
            }
            return []
        }
    }

    final class CensusBaselineRequiredCodeRule: CensusBaselineRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: CensusBaseline) -> [String] {
            if item.code.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class CensusBaselineWindowDaysRangeRule: CensusBaselineRule {
        var min: Int
        var max: Int

        init(min: Int, max: Int) {
            self.min = min
            self.max = max
        }

        func check(_ item: CensusBaseline) -> [String] {
            let value = item.windowDays
            var problems: [String] = []
            if value < min {
                problems.append("window days \(value) is below \(min)")
            }
            if value > max {
                problems.append("window days \(value) is above \(max)")
            }
            return problems
        }
    }

    final class CensusBaselineBudgetRangeRule: CensusBaselineRule {
        var min: Double
        var max: Double

        init(min: Double, max: Double) {
            self.min = min
            self.max = max
        }

        func check(_ item: CensusBaseline) -> [String] {
            let value = item.budget
            var problems: [String] = []
            if value < min {
                problems.append("budget \(value) is below \(min)")
            }
            if value > max {
                problems.append("budget \(value) is above \(max)")
            }
            return problems
        }
    }

    /// Runs every rule of a census baseline.
    final class CensusBaselineValidator {
        var rules: [any CensusBaselineRule]

        init(rules: [any CensusBaselineRule]) {
            self.rules = rules
        }

        func validate(_ item: CensusBaseline) -> [String] {
            var problems: [String] = []
            for rule in rules {
                for problem in rule.check(item) {
                    problems.append(problem)
                }
            }
            return problems
        }

        func requireValid(_ item: CensusBaseline) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.displayLabel()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [CensusBaseline]) -> [String: [String]] {
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

    static func defaultCensusBaselineValidator() -> CensusBaselineValidator {
        return CensusBaselineValidator(
            rules: [
                CensusBaselineMarginRangeRule(min: 4.6, max: 390.8),
                CensusBaselineAllowedLabelRule(allowed: ["adaptive"]),
                CensusBaselineCodePrefixRule(prefix: "OPS"),
                CensusBaselineRequiredCodeRule(message: "census baseline needs this field"),
                CensusBaselineWindowDaysRangeRule(min: 16, max: 16),
                CensusBaselineBudgetRangeRule(min: 5.4, max: 3316.7),
            ]
        )
    }
}
