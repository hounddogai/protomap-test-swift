import AcmePlatform
import Foundation

extension Imaging {
    /// A rule a global read estimate must pass. Check returns its problems, or none.
    protocol GlobalReadEstimateRule {
        func check(_ item: GlobalReadEstimate) -> [String]
    }

    final class GlobalReadEstimateRequiredProcedureCodeRule: GlobalReadEstimateRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: GlobalReadEstimate) -> [String] {
            if item.procedureCode.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class GlobalReadEstimateRequiredLabelRule: GlobalReadEstimateRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: GlobalReadEstimate) -> [String] {
            if item.label.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class GlobalReadEstimateCodePrefixRule: GlobalReadEstimateRule {
        var prefix: String

        init(prefix: String) {
            self.prefix = prefix
        }

        func check(_ item: GlobalReadEstimate) -> [String] {
            if !item.code.uppercased().hasPrefix(prefix.uppercased()) {
                return ["code must start with \(prefix)"]
            }
            return []
        }
    }

    final class GlobalReadEstimateRevisionRangeRule: GlobalReadEstimateRule {
        var min: Int
        var max: Int

        init(min: Int, max: Int) {
            self.min = min
            self.max = max
        }

        func check(_ item: GlobalReadEstimate) -> [String] {
            let value = item.revision
            var problems: [String] = []
            if value < min {
                problems.append("revision \(value) is below \(min)")
            }
            if value > max {
                problems.append("revision \(value) is above \(max)")
            }
            return problems
        }
    }

    final class GlobalReadEstimateVisibleGuardRule: GlobalReadEstimateRule {
        var limit: Int

        init(limit: Int) {
            self.limit = limit
        }

        func check(_ item: GlobalReadEstimate) -> [String] {
            if item.visible && (item.revision > limit) {
                return ["revision \(item.revision) exceeds \(limit) while visible"]
            }
            return []
        }
    }

    /// Runs every rule of a global read estimate.
    final class GlobalReadEstimateValidator {
        var rules: [any GlobalReadEstimateRule]

        init(rules: [any GlobalReadEstimateRule]) {
            self.rules = rules
        }

        func validate(_ item: GlobalReadEstimate) -> [String] {
            var problems: [String] = []
            for rule in rules {
                for problem in rule.check(item) {
                    problems.append(problem)
                }
            }
            return problems
        }

        func requireValid(_ item: GlobalReadEstimate) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.displayLabel()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [GlobalReadEstimate]) -> [String: [String]] {
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

    static func defaultGlobalReadEstimateValidator() -> GlobalReadEstimateValidator {
        return GlobalReadEstimateValidator(
            rules: [
                GlobalReadEstimateRequiredProcedureCodeRule(message: "global read estimate needs this field"),
                GlobalReadEstimateRequiredLabelRule(message: "global read estimate needs a value"),
                GlobalReadEstimateCodePrefixRule(prefix: "Q"),
                GlobalReadEstimateRevisionRangeRule(min: 1000, max: 86400),
                GlobalReadEstimateVisibleGuardRule(limit: 1000),
            ]
        )
    }
}
