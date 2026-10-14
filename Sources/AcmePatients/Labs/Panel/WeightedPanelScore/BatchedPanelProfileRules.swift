import AcmePlatform
import Foundation

extension Labs {
    /// A rule a batched panel profile must pass. Check returns its problems, or none.
    protocol BatchedPanelProfileRule {
        func check(_ item: BatchedPanelProfile) -> [String]
    }

    final class BatchedPanelProfileCodeLengthRule: BatchedPanelProfileRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: BatchedPanelProfile) -> [String] {
            let size = item.code.count
            if size > maxLength {
                return ["code is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class BatchedPanelProfileAllowedDescriptionRule: BatchedPanelProfileRule {
        var allowed: [String]

        init(allowed: [String]) {
            self.allowed = allowed
        }

        func check(_ item: BatchedPanelProfile) -> [String] {
            if allowed.count == 0 {
                return []
            }
            if !allowed.contains(Kit.Text.normalize(item.description)) {
                return ["description \(item.description) is stale"]
            }
            return []
        }
    }

    final class BatchedPanelProfileDescriptionLengthRule: BatchedPanelProfileRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: BatchedPanelProfile) -> [String] {
            let size = item.description.count
            if size > maxLength {
                return ["description is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class BatchedPanelProfileFloorValueRangeRule: BatchedPanelProfileRule {
        var min: Double
        var max: Double

        init(min: Double, max: Double) {
            self.min = min
            self.max = max
        }

        func check(_ item: BatchedPanelProfile) -> [String] {
            let value = item.floorValue
            var problems: [String] = []
            if value < min {
                problems.append("floor value \(value) is below \(min)")
            }
            if value > max {
                problems.append("floor value \(value) is above \(max)")
            }
            return problems
        }
    }

    final class BatchedPanelProfileBudgetRangeRule: BatchedPanelProfileRule {
        var min: Double
        var max: Double

        init(min: Double, max: Double) {
            self.min = min
            self.max = max
        }

        func check(_ item: BatchedPanelProfile) -> [String] {
            let value = item.budget
            if value < min || value > max {
                return ["budget \(value) is outside \(min) to \(max)"]
            }
            return []
        }
    }

    final class BatchedPanelProfileCopayRangeRule: BatchedPanelProfileRule {
        var min: Double
        var max: Double

        init(min: Double, max: Double) {
            self.min = min
            self.max = max
        }

        func check(_ item: BatchedPanelProfile) -> [String] {
            let value = item.copay
            if value < min || value > max {
                return ["copay \(value) is outside \(min) to \(max)"]
            }
            return []
        }
    }

    /// Runs every rule of a batched panel profile.
    final class BatchedPanelProfileValidator {
        var rules: [any BatchedPanelProfileRule]

        init(rules: [any BatchedPanelProfileRule]) {
            self.rules = rules
        }

        func validate(_ item: BatchedPanelProfile) -> [String] {
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

        func requireValid(_ item: BatchedPanelProfile) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.label()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [BatchedPanelProfile]) -> [String: [String]] {
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

    static func defaultBatchedPanelProfileValidator() -> BatchedPanelProfileValidator {
        return BatchedPanelProfileValidator(
            rules: [
                BatchedPanelProfileCodeLengthRule(maxLength: 64),
                BatchedPanelProfileAllowedDescriptionRule(allowed: []),
                BatchedPanelProfileDescriptionLengthRule(maxLength: 86400),
                BatchedPanelProfileFloorValueRangeRule(min: 6.7, max: 4851.6),
                BatchedPanelProfileBudgetRangeRule(min: 0.1, max: 3375.6),
                BatchedPanelProfileCopayRangeRule(min: 7.5, max: 4819.5),
            ]
        )
    }
}
