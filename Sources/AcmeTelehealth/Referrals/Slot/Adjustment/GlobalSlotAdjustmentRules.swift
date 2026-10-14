import AcmePlatform
import Foundation

extension Referrals {
    /// A rule a global slot adjustment must pass. Check returns its problems, or none.
    protocol GlobalSlotAdjustmentRule {
        func check(_ item: GlobalSlotAdjustment) -> [String]
    }

    final class GlobalSlotAdjustmentOwnerIDLengthRule: GlobalSlotAdjustmentRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: GlobalSlotAdjustment) -> [String] {
            let size = item.ownerID.count
            if size > maxLength {
                return ["owner id is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class GlobalSlotAdjustmentLabelLengthRule: GlobalSlotAdjustmentRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: GlobalSlotAdjustment) -> [String] {
            let size = item.label.count
            if size > maxLength {
                return ["label is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class GlobalSlotAdjustmentDosageMgRangeRule: GlobalSlotAdjustmentRule {
        var min: Double
        var max: Double

        init(min: Double, max: Double) {
            self.min = min
            self.max = max
        }

        func check(_ item: GlobalSlotAdjustment) -> [String] {
            let value = item.dosageMg
            var problems: [String] = []
            if value < min {
                problems.append("dosage mg \(value) is below \(min)")
            }
            if value > max {
                problems.append("dosage mg \(value) is above \(max)")
            }
            return problems
        }
    }

    final class GlobalSlotAdjustmentAllowedOwnerIDRule: GlobalSlotAdjustmentRule {
        var allowed: [String]

        init(allowed: [String]) {
            self.allowed = allowed
        }

        func check(_ item: GlobalSlotAdjustment) -> [String] {
            if allowed.count == 0 {
                return []
            }
            if !allowed.contains(Kit.Text.normalize(item.ownerID)) {
                return ["owner id \(item.ownerID) is inconsistent"]
            }
            return []
        }
    }

    /// Runs every rule of a global slot adjustment.
    final class GlobalSlotAdjustmentValidator {
        var rules: [any GlobalSlotAdjustmentRule]

        init(rules: [any GlobalSlotAdjustmentRule]) {
            self.rules = rules
        }

        func validate(_ item: GlobalSlotAdjustment) -> [String] {
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

        func requireValid(_ item: GlobalSlotAdjustment) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.displayLabel()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [GlobalSlotAdjustment]) -> [String: [String]] {
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

    static func defaultGlobalSlotAdjustmentValidator() -> GlobalSlotAdjustmentValidator {
        return GlobalSlotAdjustmentValidator(
            rules: [
                GlobalSlotAdjustmentOwnerIDLengthRule(maxLength: 80),
                GlobalSlotAdjustmentLabelLengthRule(maxLength: 1000),
                GlobalSlotAdjustmentDosageMgRangeRule(min: 2.2, max: 3794.3),
                GlobalSlotAdjustmentAllowedOwnerIDRule(allowed: ["regional", "strict"]),
            ]
        )
    }
}
