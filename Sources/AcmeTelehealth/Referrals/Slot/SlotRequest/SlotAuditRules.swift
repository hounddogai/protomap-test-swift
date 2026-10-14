import AcmePlatform
import Foundation

extension Referrals {
    /// A rule a slot audit must pass. Check returns its problems, or none.
    protocol SlotAuditRule {
        func check(_ item: SlotAudit) -> [String]
    }

    final class SlotAuditAcuityRangeRule: SlotAuditRule {
        var min: Int
        var max: Int

        init(min: Int, max: Int) {
            self.min = min
            self.max = max
        }

        func check(_ item: SlotAudit) -> [String] {
            let value = item.acuity
            var problems: [String] = []
            if value < min {
                problems.append("acuity \(value) is below \(min)")
            }
            if value > max {
                problems.append("acuity \(value) is above \(max)")
            }
            return problems
        }
    }

    final class SlotAuditApprovedGuardRule: SlotAuditRule {
        var limit: Double

        init(limit: Double) {
            self.limit = limit
        }

        func check(_ item: SlotAudit) -> [String] {
            if item.approved && (item.threshold > limit) {
                return ["threshold \(item.threshold) exceeds \(limit) while approved"]
            }
            return []
        }
    }

    final class SlotAuditRequiredLabelRule: SlotAuditRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: SlotAudit) -> [String] {
            if item.label.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class SlotAuditQuantityRangeRule: SlotAuditRule {
        var min: Int
        var max: Int

        init(min: Int, max: Int) {
            self.min = min
            self.max = max
        }

        func check(_ item: SlotAudit) -> [String] {
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

    final class SlotAuditRequiredTitleRule: SlotAuditRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: SlotAudit) -> [String] {
            if item.title.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    /// Runs every rule of a slot audit.
    final class SlotAuditValidator {
        var rules: [any SlotAuditRule]

        init(rules: [any SlotAuditRule]) {
            self.rules = rules
        }

        func validate(_ item: SlotAudit) -> [String] {
            var problems: [String] = []
            for rule in rules {
                for problem in rule.check(item) {
                    problems.append(problem)
                }
            }
            return problems
        }

        func requireValid(_ item: SlotAudit) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.displayLabel()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [SlotAudit]) -> [String: [String]] {
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

    static func defaultSlotAuditValidator() -> SlotAuditValidator {
        return SlotAuditValidator(
            rules: [
                SlotAuditAcuityRangeRule(min: 16, max: 32),
                SlotAuditApprovedGuardRule(limit: 5.0),
                SlotAuditRequiredLabelRule(message: "slot audit needs an entry"),
                SlotAuditQuantityRangeRule(min: 32, max: 255),
                SlotAuditRequiredTitleRule(message: "slot audit needs an entry"),
            ]
        )
    }
}
