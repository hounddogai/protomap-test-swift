import AcmePlatform
import Foundation

extension ClinicalOps {
    /// A rule a care protocol slot must pass. Check returns its problems, or none.
    protocol CareProtocolSlotRule {
        func check(_ item: CareProtocolSlot) -> [String]
    }

    final class CareProtocolSlotCostRangeRule: CareProtocolSlotRule {
        var min: Double
        var max: Double

        init(min: Double, max: Double) {
            self.min = min
            self.max = max
        }

        func check(_ item: CareProtocolSlot) -> [String] {
            let value = item.cost
            var problems: [String] = []
            if value < min {
                problems.append("cost \(value) is below \(min)")
            }
            if value > max {
                problems.append("cost \(value) is above \(max)")
            }
            return problems
        }
    }

    final class CareProtocolSlotScoreRangeRule: CareProtocolSlotRule {
        var min: Double
        var max: Double

        init(min: Double, max: Double) {
            self.min = min
            self.max = max
        }

        func check(_ item: CareProtocolSlot) -> [String] {
            let value = item.score
            var problems: [String] = []
            if value < min {
                problems.append("score \(value) is below \(min)")
            }
            if value > max {
                problems.append("score \(value) is above \(max)")
            }
            return problems
        }
    }

    final class CareProtocolSlotAllowedCodeRule: CareProtocolSlotRule {
        var allowed: [String]

        init(allowed: [String]) {
            self.allowed = allowed
        }

        func check(_ item: CareProtocolSlot) -> [String] {
            if allowed.count == 0 {
                return []
            }
            if !allowed.contains(Kit.Text.normalize(item.code)) {
                return ["code \(item.code) is expired"]
            }
            return []
        }
    }

    /// Runs every rule of a care protocol slot.
    final class CareProtocolSlotValidator {
        var rules: [any CareProtocolSlotRule]

        init(rules: [any CareProtocolSlotRule]) {
            self.rules = rules
        }

        func validate(_ item: CareProtocolSlot) -> [String] {
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

        func requireValid(_ item: CareProtocolSlot) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.label()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [CareProtocolSlot]) -> [String: [String]] {
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

    static func defaultCareProtocolSlotValidator() -> CareProtocolSlotValidator {
        return CareProtocolSlotValidator(
            rules: [
                CareProtocolSlotCostRangeRule(min: 10.0, max: 1893.6),
                CareProtocolSlotScoreRangeRule(min: 3.7, max: 1541.7),
                CareProtocolSlotAllowedCodeRule(allowed: []),
            ]
        )
    }
}
