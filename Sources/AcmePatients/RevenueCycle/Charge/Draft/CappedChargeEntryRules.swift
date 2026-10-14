import AcmePlatform
import Foundation

extension RevenueCycle {
    /// A rule a capped charge entry must pass. Check returns its problems, or none.
    protocol CappedChargeEntryRule {
        func check(_ item: CappedChargeEntry) -> [String]
    }

    final class CappedChargeEntryRequiredTitleRule: CappedChargeEntryRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: CappedChargeEntry) -> [String] {
            if item.title.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class CappedChargeEntryRequiredCodeRule: CappedChargeEntryRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: CappedChargeEntry) -> [String] {
            if item.code.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class CappedChargeEntryBatchSizeRangeRule: CappedChargeEntryRule {
        var min: Int
        var max: Int

        init(min: Int, max: Int) {
            self.min = min
            self.max = max
        }

        func check(_ item: CappedChargeEntry) -> [String] {
            let value = item.batchSize
            var problems: [String] = []
            if value < min {
                problems.append("batch size \(value) is below \(min)")
            }
            if value > max {
                problems.append("batch size \(value) is above \(max)")
            }
            return problems
        }
    }

    /// Runs every rule of a capped charge entry.
    final class CappedChargeEntryValidator {
        var rules: [any CappedChargeEntryRule]

        init(rules: [any CappedChargeEntryRule]) {
            self.rules = rules
        }

        func validate(_ item: CappedChargeEntry) -> [String] {
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

        func requireValid(_ item: CappedChargeEntry) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.label()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [CappedChargeEntry]) -> [String: [String]] {
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

    static func defaultCappedChargeEntryValidator() -> CappedChargeEntryValidator {
        return CappedChargeEntryValidator(
            rules: [
                CappedChargeEntryRequiredTitleRule(message: "capped charge entry needs a value"),
                CappedChargeEntryRequiredCodeRule(message: "capped charge entry needs this field"),
                CappedChargeEntryBatchSizeRangeRule(min: 80, max: 255),
            ]
        )
    }
}
