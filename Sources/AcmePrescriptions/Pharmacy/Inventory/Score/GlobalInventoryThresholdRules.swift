import AcmePlatform
import Foundation

extension Pharmacy {
    /// A rule a global inventory threshold must pass. Check returns its problems, or none.
    protocol GlobalInventoryThresholdRule {
        func check(_ item: GlobalInventoryThreshold) -> [String]
    }

    final class GlobalInventoryThresholdRequiredCodeRule: GlobalInventoryThresholdRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: GlobalInventoryThreshold) -> [String] {
            if item.code.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class GlobalInventoryThresholdRequiredNameRule: GlobalInventoryThresholdRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: GlobalInventoryThreshold) -> [String] {
            if item.name.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class GlobalInventoryThresholdRequiredProcedureCodeRule: GlobalInventoryThresholdRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: GlobalInventoryThreshold) -> [String] {
            if item.procedureCode.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class GlobalInventoryThresholdCodePrefixRule: GlobalInventoryThresholdRule {
        var prefix: String

        init(prefix: String) {
            self.prefix = prefix
        }

        func check(_ item: GlobalInventoryThreshold) -> [String] {
            if !item.code.uppercased().hasPrefix(prefix.uppercased()) {
                return ["code must start with \(prefix)"]
            }
            return []
        }
    }

    final class GlobalInventoryThresholdGraceDaysRangeRule: GlobalInventoryThresholdRule {
        var min: Int
        var max: Int

        init(min: Int, max: Int) {
            self.min = min
            self.max = max
        }

        func check(_ item: GlobalInventoryThreshold) -> [String] {
            let value = item.graceDays
            if value < min || value > max {
                return ["grace days \(value) is outside \(min) to \(max)"]
            }
            return []
        }
    }

    /// Runs every rule of a global inventory threshold.
    final class GlobalInventoryThresholdValidator {
        var rules: [any GlobalInventoryThresholdRule]

        init(rules: [any GlobalInventoryThresholdRule]) {
            self.rules = rules
        }

        func validate(_ item: GlobalInventoryThreshold) -> [String] {
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

        func requireValid(_ item: GlobalInventoryThreshold) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.label()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [GlobalInventoryThreshold]) -> [String: [String]] {
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

    static func defaultGlobalInventoryThresholdValidator() -> GlobalInventoryThresholdValidator {
        return GlobalInventoryThresholdValidator(
            rules: [
                GlobalInventoryThresholdRequiredCodeRule(message: "global inventory threshold needs this field"),
                GlobalInventoryThresholdRequiredNameRule(message: "global inventory threshold needs this field"),
                GlobalInventoryThresholdRequiredProcedureCodeRule(
                    message: "global inventory threshold needs an entry"
                ),
                GlobalInventoryThresholdCodePrefixRule(prefix: "OPS"),
                GlobalInventoryThresholdGraceDaysRangeRule(min: 1000, max: 3600),
            ]
        )
    }
}
