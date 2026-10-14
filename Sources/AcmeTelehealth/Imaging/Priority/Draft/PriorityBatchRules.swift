import AcmePlatform
import Foundation

extension Imaging {
    /// A rule a priority batch must pass. Check returns its problems, or none.
    protocol PriorityBatchRule {
        func check(_ item: PriorityBatch) -> [String]
    }

    final class PriorityBatchGraceDaysRangeRule: PriorityBatchRule {
        var min: Int
        var max: Int

        init(min: Int, max: Int) {
            self.min = min
            self.max = max
        }

        func check(_ item: PriorityBatch) -> [String] {
            let value = item.graceDays
            if value < min || value > max {
                return ["grace days \(value) is outside \(min) to \(max)"]
            }
            return []
        }
    }

    final class PriorityBatchRegionLengthRule: PriorityBatchRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: PriorityBatch) -> [String] {
            let size = item.region.count
            if size > maxLength {
                return ["region is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class PriorityBatchCeilingRangeRule: PriorityBatchRule {
        var min: Double
        var max: Double

        init(min: Double, max: Double) {
            self.min = min
            self.max = max
        }

        func check(_ item: PriorityBatch) -> [String] {
            let value = item.ceiling
            var problems: [String] = []
            if value < min {
                problems.append("ceiling \(value) is below \(min)")
            }
            if value > max {
                problems.append("ceiling \(value) is above \(max)")
            }
            return problems
        }
    }

    final class PriorityBatchLabelLengthRule: PriorityBatchRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: PriorityBatch) -> [String] {
            let size = item.label.count
            if size > maxLength {
                return ["label is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class PriorityBatchNotesLengthRule: PriorityBatchRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: PriorityBatch) -> [String] {
            let size = item.notes.count
            if size > maxLength {
                return ["notes is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    /// Runs every rule of a priority batch.
    final class PriorityBatchValidator {
        var rules: [any PriorityBatchRule]

        init(rules: [any PriorityBatchRule]) {
            self.rules = rules
        }

        func validate(_ item: PriorityBatch) -> [String] {
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

        func requireValid(_ item: PriorityBatch) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.displayLabel()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [PriorityBatch]) -> [String: [String]] {
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

    static func defaultPriorityBatchValidator() -> PriorityBatchValidator {
        return PriorityBatchValidator(
            rules: [
                PriorityBatchGraceDaysRangeRule(min: 64, max: 86400),
                PriorityBatchRegionLengthRule(maxLength: 80),
                PriorityBatchCeilingRangeRule(min: 0.4, max: 2443.9),
                PriorityBatchLabelLengthRule(maxLength: 255),
                PriorityBatchNotesLengthRule(maxLength: 80),
            ]
        )
    }
}
