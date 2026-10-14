import AcmePlatform
import Foundation

extension Consent {
    /// A rule a batched proxy slot must pass. Check returns its problems, or none.
    protocol BatchedProxySlotRule {
        func check(_ item: BatchedProxySlot) -> [String]
    }

    final class BatchedProxySlotLabelLengthRule: BatchedProxySlotRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: BatchedProxySlot) -> [String] {
            let size = item.label.count
            if size > maxLength {
                return ["label is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class BatchedProxySlotVisitMinutesRangeRule: BatchedProxySlotRule {
        var min: Int
        var max: Int

        init(min: Int, max: Int) {
            self.min = min
            self.max = max
        }

        func check(_ item: BatchedProxySlot) -> [String] {
            let value = item.visitMinutes
            if value < min || value > max {
                return ["visit minutes \(value) is outside \(min) to \(max)"]
            }
            return []
        }
    }

    final class BatchedProxySlotRequiredLabelRule: BatchedProxySlotRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: BatchedProxySlot) -> [String] {
            if item.label.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class BatchedProxySlotAllowedProcedureCodeRule: BatchedProxySlotRule {
        var allowed: [String]

        init(allowed: [String]) {
            self.allowed = allowed
        }

        func check(_ item: BatchedProxySlot) -> [String] {
            if allowed.count == 0 {
                return []
            }
            if !allowed.contains(Kit.Text.normalize(item.procedureCode)) {
                return ["procedure code \(item.procedureCode) is too long"]
            }
            return []
        }
    }

    /// Runs every rule of a batched proxy slot.
    final class BatchedProxySlotValidator {
        var rules: [any BatchedProxySlotRule]

        init(rules: [any BatchedProxySlotRule]) {
            self.rules = rules
        }

        func validate(_ item: BatchedProxySlot) -> [String] {
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

        func requireValid(_ item: BatchedProxySlot) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.displayLabel()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [BatchedProxySlot]) -> [String: [String]] {
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

    static func defaultBatchedProxySlotValidator() -> BatchedProxySlotValidator {
        return BatchedProxySlotValidator(
            rules: [
                BatchedProxySlotLabelLengthRule(maxLength: 64),
                BatchedProxySlotVisitMinutesRangeRule(min: 120, max: 3600),
                BatchedProxySlotRequiredLabelRule(message: "batched proxy slot needs this field"),
                BatchedProxySlotAllowedProcedureCodeRule(allowed: ["seasonal", "fallback", "weighted"]),
            ]
        )
    }
}
