import AcmePlatform
import Foundation

extension Referrals {
    /// A rule a strict slot batch must pass. Check returns its problems, or none.
    protocol StrictSlotBatchRule {
        func check(_ item: StrictSlotBatch) -> [String]
    }

    final class StrictSlotBatchCodePrefixRule: StrictSlotBatchRule {
        var prefix: String

        init(prefix: String) {
            self.prefix = prefix
        }

        func check(_ item: StrictSlotBatch) -> [String] {
            if !item.code.uppercased().hasPrefix(prefix.uppercased()) {
                return ["code must start with \(prefix)"]
            }
            return []
        }
    }

    final class StrictSlotBatchRequiredLabelRule: StrictSlotBatchRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: StrictSlotBatch) -> [String] {
            if item.label.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class StrictSlotBatchRequiredClinicianIDRule: StrictSlotBatchRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: StrictSlotBatch) -> [String] {
            if item.clinicianID.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class StrictSlotBatchRequiredCodeRule: StrictSlotBatchRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: StrictSlotBatch) -> [String] {
            if item.code.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class StrictSlotBatchQuantityRangeRule: StrictSlotBatchRule {
        var min: Int
        var max: Int

        init(min: Int, max: Int) {
            self.min = min
            self.max = max
        }

        func check(_ item: StrictSlotBatch) -> [String] {
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

    /// Runs every rule of a strict slot batch.
    final class StrictSlotBatchValidator {
        var rules: [any StrictSlotBatchRule]

        init(rules: [any StrictSlotBatchRule]) {
            self.rules = rules
        }

        func validate(_ item: StrictSlotBatch) -> [String] {
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

        func requireValid(_ item: StrictSlotBatch) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.displayLabel()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [StrictSlotBatch]) -> [String: [String]] {
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

    static func defaultStrictSlotBatchValidator() -> StrictSlotBatchValidator {
        return StrictSlotBatchValidator(
            rules: [
                StrictSlotBatchCodePrefixRule(prefix: "REF"),
                StrictSlotBatchRequiredLabelRule(message: "strict slot batch needs a value"),
                StrictSlotBatchRequiredClinicianIDRule(message: "strict slot batch needs an entry"),
                StrictSlotBatchRequiredCodeRule(message: "strict slot batch needs this field"),
                StrictSlotBatchQuantityRangeRule(min: 80, max: 120),
            ]
        )
    }
}
