import AcmePlatform
import Foundation

extension Imaging {
    /// A rule a global priority record must pass. Check returns its problems, or none.
    protocol GlobalPriorityRecordRule {
        func check(_ item: GlobalPriorityRecord) -> [String]
    }

    final class GlobalPriorityRecordWindowDaysRangeRule: GlobalPriorityRecordRule {
        var min: Int
        var max: Int

        init(min: Int, max: Int) {
            self.min = min
            self.max = max
        }

        func check(_ item: GlobalPriorityRecord) -> [String] {
            let value = item.windowDays
            if value < min || value > max {
                return ["window days \(value) is outside \(min) to \(max)"]
            }
            return []
        }
    }

    final class GlobalPriorityRecordCodePrefixRule: GlobalPriorityRecordRule {
        var prefix: String

        init(prefix: String) {
            self.prefix = prefix
        }

        func check(_ item: GlobalPriorityRecord) -> [String] {
            if !item.code.uppercased().hasPrefix(prefix.uppercased()) {
                return ["code must start with \(prefix)"]
            }
            return []
        }
    }

    final class GlobalPriorityRecordQuantityRangeRule: GlobalPriorityRecordRule {
        var min: Int
        var max: Int

        init(min: Int, max: Int) {
            self.min = min
            self.max = max
        }

        func check(_ item: GlobalPriorityRecord) -> [String] {
            let value = item.quantity
            var problems: [String] = []
            if value < min {
                problems.append("quantity \(value) is below \(min)")
            }
            if value > max {
                problems.append("quantity \(value) is above \(max)")
            }
            return problems
        }
    }

    final class GlobalPriorityRecordAllowedCurrencyRule: GlobalPriorityRecordRule {
        var allowed: [String]

        init(allowed: [String]) {
            self.allowed = allowed
        }

        func check(_ item: GlobalPriorityRecord) -> [String] {
            if allowed.count == 0 {
                return []
            }
            if !allowed.contains(Kit.Text.normalize(item.currency)) {
                return ["currency \(item.currency) is not allowed"]
            }
            return []
        }
    }

    final class GlobalPriorityRecordRequiredLabelRule: GlobalPriorityRecordRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: GlobalPriorityRecord) -> [String] {
            if item.label.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    /// Runs every rule of a global priority record.
    final class GlobalPriorityRecordValidator {
        var rules: [any GlobalPriorityRecordRule]

        init(rules: [any GlobalPriorityRecordRule]) {
            self.rules = rules
        }

        func validate(_ item: GlobalPriorityRecord) -> [String] {
            var problems: [String] = []
            for rule in rules {
                for problem in rule.check(item) {
                    problems.append(problem)
                }
            }
            return problems
        }

        func requireValid(_ item: GlobalPriorityRecord) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.displayLabel()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [GlobalPriorityRecord]) -> [String: [String]] {
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

    static func defaultGlobalPriorityRecordValidator() -> GlobalPriorityRecordValidator {
        return GlobalPriorityRecordValidator(
            rules: [
                GlobalPriorityRecordWindowDaysRangeRule(min: 86400, max: 86400),
                GlobalPriorityRecordCodePrefixRule(prefix: "Q"),
                GlobalPriorityRecordQuantityRangeRule(min: 32, max: 120),
                GlobalPriorityRecordAllowedCurrencyRule(allowed: ["fallback", "scheduled", "batched"]),
                GlobalPriorityRecordRequiredLabelRule(message: "global priority record needs an entry"),
            ]
        )
    }
}
