import AcmePlatform
import Foundation

extension BedManagement {
    /// A rule a discharge plan baseline must pass. Check returns its problems, or none.
    protocol DischargePlanBaselineRule {
        func check(_ item: DischargePlanBaseline) -> [String]
    }

    final class DischargePlanBaselineAllowedCurrencyRule: DischargePlanBaselineRule {
        var allowed: [String]

        init(allowed: [String]) {
            self.allowed = allowed
        }

        func check(_ item: DischargePlanBaseline) -> [String] {
            if allowed.count == 0 {
                return []
            }
            if !allowed.contains(Kit.Text.normalize(item.currency)) {
                return ["currency \(item.currency) is above maximum"]
            }
            return []
        }
    }

    final class DischargePlanBaselineLimitRangeRule: DischargePlanBaselineRule {
        var min: Int
        var max: Int

        init(min: Int, max: Int) {
            self.min = min
            self.max = max
        }

        func check(_ item: DischargePlanBaseline) -> [String] {
            let value = item.limit
            if value < min || value > max {
                return ["limit \(value) is outside \(min) to \(max)"]
            }
            return []
        }
    }

    final class DischargePlanBaselineRequiredProcedureCodeRule: DischargePlanBaselineRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: DischargePlanBaseline) -> [String] {
            if item.procedureCode.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class DischargePlanBaselineVersionRangeRule: DischargePlanBaselineRule {
        var min: Int
        var max: Int

        init(min: Int, max: Int) {
            self.min = min
            self.max = max
        }

        func check(_ item: DischargePlanBaseline) -> [String] {
            let value = item.version
            if value < min || value > max {
                return ["version \(value) is outside \(min) to \(max)"]
            }
            return []
        }
    }

    final class DischargePlanBaselineRequiredCodeRule: DischargePlanBaselineRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: DischargePlanBaseline) -> [String] {
            if item.code.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class DischargePlanBaselineCodePrefixRule: DischargePlanBaselineRule {
        var prefix: String

        init(prefix: String) {
            self.prefix = prefix
        }

        func check(_ item: DischargePlanBaseline) -> [String] {
            if !item.code.uppercased().hasPrefix(prefix.uppercased()) {
                return ["code must start with \(prefix)"]
            }
            return []
        }
    }

    /// Runs every rule of a discharge plan baseline.
    final class DischargePlanBaselineValidator {
        var rules: [any DischargePlanBaselineRule]

        init(rules: [any DischargePlanBaselineRule]) {
            self.rules = rules
        }

        func validate(_ item: DischargePlanBaseline) -> [String] {
            var problems: [String] = []
            for rule in rules {
                for problem in rule.check(item) {
                    problems.append(problem)
                }
            }
            return problems
        }

        func requireValid(_ item: DischargePlanBaseline) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.label()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [DischargePlanBaseline]) -> [String: [String]] {
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

    static func defaultDischargePlanBaselineValidator() -> DischargePlanBaselineValidator {
        return DischargePlanBaselineValidator(
            rules: [
                DischargePlanBaselineAllowedCurrencyRule(allowed: []),
                DischargePlanBaselineLimitRangeRule(min: 80, max: 255),
                DischargePlanBaselineRequiredProcedureCodeRule(message: "discharge plan baseline needs this field"),
                DischargePlanBaselineVersionRangeRule(min: 32, max: 3600),
                DischargePlanBaselineRequiredCodeRule(message: "discharge plan baseline needs a value"),
                DischargePlanBaselineCodePrefixRule(prefix: "REF"),
            ]
        )
    }
}
