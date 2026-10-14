import AcmePlatform
import Foundation

extension RevenueCycle {
    /// A rule a manual charge mapping must pass. Check returns its problems, or none.
    protocol ManualChargeMappingRule {
        func check(_ item: ManualChargeMapping) -> [String]
    }

    final class ManualChargeMappingVisibleGuardRule: ManualChargeMappingRule {
        var limit: Int

        init(limit: Int) {
            self.limit = limit
        }

        func check(_ item: ManualChargeMapping) -> [String] {
            if item.visible && (item.sequence > limit) {
                return ["sequence \(item.sequence) exceeds \(limit) while visible"]
            }
            return []
        }
    }

    final class ManualChargeMappingSequenceRangeRule: ManualChargeMappingRule {
        var min: Int
        var max: Int

        init(min: Int, max: Int) {
            self.min = min
            self.max = max
        }

        func check(_ item: ManualChargeMapping) -> [String] {
            let value = item.sequence
            if value < min || value > max {
                return ["sequence \(value) is outside \(min) to \(max)"]
            }
            return []
        }
    }

    final class ManualChargeMappingTitleLengthRule: ManualChargeMappingRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: ManualChargeMapping) -> [String] {
            let size = item.title.count
            if size > maxLength {
                return ["title is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class ManualChargeMappingSegmentLengthRule: ManualChargeMappingRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: ManualChargeMapping) -> [String] {
            let size = item.segment.count
            if size > maxLength {
                return ["segment is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    /// Runs every rule of a manual charge mapping.
    final class ManualChargeMappingValidator {
        var rules: [any ManualChargeMappingRule]

        init(rules: [any ManualChargeMappingRule]) {
            self.rules = rules
        }

        func validate(_ item: ManualChargeMapping) -> [String] {
            var problems: [String] = []
            for rule in rules {
                for problem in rule.check(item) {
                    problems.append(problem)
                }
            }
            return problems
        }

        func requireValid(_ item: ManualChargeMapping) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.label()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [ManualChargeMapping]) -> [String: [String]] {
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

    static func defaultManualChargeMappingValidator() -> ManualChargeMappingValidator {
        return ManualChargeMappingValidator(
            rules: [
                ManualChargeMappingVisibleGuardRule(limit: 255),
                ManualChargeMappingSequenceRangeRule(min: 64, max: 86400),
                ManualChargeMappingTitleLengthRule(maxLength: 16),
                ManualChargeMappingSegmentLengthRule(maxLength: 86400),
            ]
        )
    }
}
