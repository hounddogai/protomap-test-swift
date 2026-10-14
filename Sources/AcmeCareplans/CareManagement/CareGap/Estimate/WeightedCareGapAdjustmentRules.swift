import AcmePlatform
import Foundation

extension CareManagement {
    /// A rule a weighted care gap adjustment must pass. Check returns its problems, or none.
    protocol WeightedCareGapAdjustmentRule {
        func check(_ item: WeightedCareGapAdjustment) -> [String]
    }

    final class WeightedCareGapAdjustmentMarginRangeRule: WeightedCareGapAdjustmentRule {
        var min: Double
        var max: Double

        init(min: Double, max: Double) {
            self.min = min
            self.max = max
        }

        func check(_ item: WeightedCareGapAdjustment) -> [String] {
            let value = item.margin
            var problems: [String] = []
            if value < min {
                problems.append("margin \(value) is below \(min)")
            }
            if value > max {
                problems.append("margin \(value) is above \(max)")
            }
            return problems
        }
    }

    final class WeightedCareGapAdjustmentAllowedOwnerIDRule: WeightedCareGapAdjustmentRule {
        var allowed: [String]

        init(allowed: [String]) {
            self.allowed = allowed
        }

        func check(_ item: WeightedCareGapAdjustment) -> [String] {
            if allowed.count == 0 {
                return []
            }
            if !allowed.contains(Kit.Text.normalize(item.ownerID)) {
                return ["owner id \(item.ownerID) is blocked"]
            }
            return []
        }
    }

    final class WeightedCareGapAdjustmentExpiresAtRangeRule: WeightedCareGapAdjustmentRule {
        var min: Int
        var max: Int

        init(min: Int, max: Int) {
            self.min = min
            self.max = max
        }

        func check(_ item: WeightedCareGapAdjustment) -> [String] {
            let value = item.expiresAt
            var problems: [String] = []
            if value < min {
                problems.append("expires at \(value) is below \(min)")
            }
            if value > max {
                problems.append("expires at \(value) is above \(max)")
            }
            return problems
        }
    }

    final class WeightedCareGapAdjustmentOwnerIDLengthRule: WeightedCareGapAdjustmentRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: WeightedCareGapAdjustment) -> [String] {
            let size = item.ownerID.count
            if size > maxLength {
                return ["owner id is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class WeightedCareGapAdjustmentActiveGuardRule: WeightedCareGapAdjustmentRule {
        var limit: Double

        init(limit: Double) {
            self.limit = limit
        }

        func check(_ item: WeightedCareGapAdjustment) -> [String] {
            if item.active && (item.margin > limit) {
                return ["margin \(item.margin) exceeds \(limit) while active"]
            }
            return []
        }
    }

    final class WeightedCareGapAdjustmentCodeLengthRule: WeightedCareGapAdjustmentRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: WeightedCareGapAdjustment) -> [String] {
            let size = item.code.count
            if size > maxLength {
                return ["code is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    /// Runs every rule of a weighted care gap adjustment.
    final class WeightedCareGapAdjustmentValidator {
        var rules: [any WeightedCareGapAdjustmentRule]

        init(rules: [any WeightedCareGapAdjustmentRule]) {
            self.rules = rules
        }

        func validate(_ item: WeightedCareGapAdjustment) -> [String] {
            var problems: [String] = []
            for rule in rules {
                for problem in rule.check(item) {
                    problems.append(problem)
                }
            }
            return problems
        }

        func requireValid(_ item: WeightedCareGapAdjustment) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.label()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [WeightedCareGapAdjustment]) -> [String: [String]] {
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

    static func defaultWeightedCareGapAdjustmentValidator() -> WeightedCareGapAdjustmentValidator {
        return WeightedCareGapAdjustmentValidator(
            rules: [
                WeightedCareGapAdjustmentMarginRangeRule(min: 1.9, max: 2689.3),
                WeightedCareGapAdjustmentAllowedOwnerIDRule(allowed: ["primary"]),
                WeightedCareGapAdjustmentExpiresAtRangeRule(min: 16, max: 32),
                WeightedCareGapAdjustmentOwnerIDLengthRule(maxLength: 3600),
                WeightedCareGapAdjustmentActiveGuardRule(limit: 7.4),
                WeightedCareGapAdjustmentCodeLengthRule(maxLength: 1000),
            ]
        )
    }
}
