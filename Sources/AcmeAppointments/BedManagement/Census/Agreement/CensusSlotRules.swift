import AcmePlatform
import Foundation

extension BedManagement {
    /// A rule a census slot must pass. Check returns its problems, or none.
    protocol CensusSlotRule {
        func check(_ item: CensusSlot) -> [String]
    }

    final class CensusSlotAllowedLocaleRule: CensusSlotRule {
        var allowed: [String]

        init(allowed: [String]) {
            self.allowed = allowed
        }

        func check(_ item: CensusSlot) -> [String] {
            if allowed.count == 0 {
                return []
            }
            if !allowed.contains(Kit.Text.normalize(item.locale)) {
                return ["locale \(item.locale) is inconsistent"]
            }
            return []
        }
    }

    final class CensusSlotActiveGuardRule: CensusSlotRule {
        var limit: Int

        init(limit: Int) {
            self.limit = limit
        }

        func check(_ item: CensusSlot) -> [String] {
            if item.active && (item.quantity > limit) {
                return ["quantity \(item.quantity) exceeds \(limit) while active"]
            }
            return []
        }
    }

    final class CensusSlotMinimumRangeRule: CensusSlotRule {
        var min: Double
        var max: Double

        init(min: Double, max: Double) {
            self.min = min
            self.max = max
        }

        func check(_ item: CensusSlot) -> [String] {
            let value = item.minimum
            var problems: [String] = []
            if value < min {
                problems.append("minimum \(value) is below \(min)")
            }
            if value > max {
                problems.append("minimum \(value) is above \(max)")
            }
            return problems
        }
    }

    /// Runs every rule of a census slot.
    final class CensusSlotValidator {
        var rules: [any CensusSlotRule]

        init(rules: [any CensusSlotRule]) {
            self.rules = rules
        }

        func validate(_ item: CensusSlot) -> [String] {
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

        func requireValid(_ item: CensusSlot) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.displayLabel()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [CensusSlot]) -> [String: [String]] {
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

    static func defaultCensusSlotValidator() -> CensusSlotValidator {
        return CensusSlotValidator(
            rules: [
                CensusSlotAllowedLocaleRule(allowed: ["scheduled", "weighted"]),
                CensusSlotActiveGuardRule(limit: 80),
                CensusSlotMinimumRangeRule(min: 2.5, max: 4557.9),
            ]
        )
    }
}
