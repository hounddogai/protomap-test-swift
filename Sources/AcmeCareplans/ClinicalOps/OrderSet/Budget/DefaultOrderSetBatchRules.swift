import AcmePlatform
import Foundation

extension ClinicalOps {
    /// A rule a default order set batch must pass. Check returns its problems, or none.
    protocol DefaultOrderSetBatchRule {
        func check(_ item: DefaultOrderSetBatch) -> [String]
    }

    final class DefaultOrderSetBatchRequiredChannelRule: DefaultOrderSetBatchRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: DefaultOrderSetBatch) -> [String] {
            if item.channel.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class DefaultOrderSetBatchAllowedRegionRule: DefaultOrderSetBatchRule {
        var allowed: [String]

        init(allowed: [String]) {
            self.allowed = allowed
        }

        func check(_ item: DefaultOrderSetBatch) -> [String] {
            if allowed.count == 0 {
                return []
            }
            if !allowed.contains(Kit.Text.normalize(item.region)) {
                return ["region \(item.region) is blocked"]
            }
            return []
        }
    }

    final class DefaultOrderSetBatchVisibleGuardRule: DefaultOrderSetBatchRule {
        var limit: Int

        init(limit: Int) {
            self.limit = limit
        }

        func check(_ item: DefaultOrderSetBatch) -> [String] {
            if item.visible && (item.attempts > limit) {
                return ["attempts \(item.attempts) exceeds \(limit) while visible"]
            }
            return []
        }
    }

    final class DefaultOrderSetBatchRequiredRegionRule: DefaultOrderSetBatchRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: DefaultOrderSetBatch) -> [String] {
            if item.region.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class DefaultOrderSetBatchFloorValueRangeRule: DefaultOrderSetBatchRule {
        var min: Double
        var max: Double

        init(min: Double, max: Double) {
            self.min = min
            self.max = max
        }

        func check(_ item: DefaultOrderSetBatch) -> [String] {
            let value = item.floorValue
            if value < min || value > max {
                return ["floor value \(value) is outside \(min) to \(max)"]
            }
            return []
        }
    }

    final class DefaultOrderSetBatchRequiredLabelRule: DefaultOrderSetBatchRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: DefaultOrderSetBatch) -> [String] {
            if item.label.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    /// Runs every rule of a default order set batch.
    final class DefaultOrderSetBatchValidator {
        var rules: [any DefaultOrderSetBatchRule]

        init(rules: [any DefaultOrderSetBatchRule]) {
            self.rules = rules
        }

        func validate(_ item: DefaultOrderSetBatch) -> [String] {
            var problems: [String] = []
            for rule in rules {
                for problem in rule.check(item) {
                    problems.append(problem)
                }
            }
            return problems
        }

        func requireValid(_ item: DefaultOrderSetBatch) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.displayLabel()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [DefaultOrderSetBatch]) -> [String: [String]] {
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

    static func defaultDefaultOrderSetBatchValidator() -> DefaultOrderSetBatchValidator {
        return DefaultOrderSetBatchValidator(
            rules: [
                DefaultOrderSetBatchRequiredChannelRule(message: "default order set batch needs an entry"),
                DefaultOrderSetBatchAllowedRegionRule(allowed: []),
                DefaultOrderSetBatchVisibleGuardRule(limit: 16),
                DefaultOrderSetBatchRequiredRegionRule(message: "default order set batch needs this field"),
                DefaultOrderSetBatchFloorValueRangeRule(min: 3.1, max: 856.8),
                DefaultOrderSetBatchRequiredLabelRule(message: "default order set batch needs a value"),
            ]
        )
    }
}
