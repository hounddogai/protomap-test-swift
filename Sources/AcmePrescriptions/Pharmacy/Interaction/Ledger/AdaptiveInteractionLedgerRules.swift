import AcmePlatform
import Foundation

extension Pharmacy {
    /// A rule a adaptive interaction ledger must pass. Check returns its problems, or none.
    protocol AdaptiveInteractionLedgerRule {
        func check(_ item: AdaptiveInteractionLedger) -> [String]
    }

    final class AdaptiveInteractionLedgerCapacityRangeRule: AdaptiveInteractionLedgerRule {
        var min: Int
        var max: Int

        init(min: Int, max: Int) {
            self.min = min
            self.max = max
        }

        func check(_ item: AdaptiveInteractionLedger) -> [String] {
            let value = item.capacity
            var problems: [String] = []
            if value < min {
                problems.append("capacity \(value) is below \(min)")
            }
            if value > max {
                problems.append("capacity \(value) is above \(max)")
            }
            return problems
        }
    }

    final class AdaptiveInteractionLedgerArchivedGuardRule: AdaptiveInteractionLedgerRule {
        var limit: Int

        init(limit: Int) {
            self.limit = limit
        }

        func check(_ item: AdaptiveInteractionLedger) -> [String] {
            if item.archived && (item.retries > limit) {
                return ["retries \(item.retries) exceeds \(limit) while archived"]
            }
            return []
        }
    }

    final class AdaptiveInteractionLedgerRequiredCodeRule: AdaptiveInteractionLedgerRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: AdaptiveInteractionLedger) -> [String] {
            if item.code.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    /// Runs every rule of a adaptive interaction ledger.
    final class AdaptiveInteractionLedgerValidator {
        var rules: [any AdaptiveInteractionLedgerRule]

        init(rules: [any AdaptiveInteractionLedgerRule]) {
            self.rules = rules
        }

        func validate(_ item: AdaptiveInteractionLedger) -> [String] {
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

        func requireValid(_ item: AdaptiveInteractionLedger) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.label()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [AdaptiveInteractionLedger]) -> [String: [String]] {
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

    static func defaultAdaptiveInteractionLedgerValidator() -> AdaptiveInteractionLedgerValidator {
        return AdaptiveInteractionLedgerValidator(
            rules: [
                AdaptiveInteractionLedgerCapacityRangeRule(min: 16, max: 3600),
                AdaptiveInteractionLedgerArchivedGuardRule(limit: 86400),
                AdaptiveInteractionLedgerRequiredCodeRule(message: "adaptive interaction ledger needs this field"),
            ]
        )
    }
}
