import AcmePlatform
import Foundation

extension Consent {
    /// A rule a regional witness batch must pass. Check returns its problems, or none.
    protocol RegionalWitnessBatchRule {
        func check(_ item: RegionalWitnessBatch) -> [String]
    }

    final class RegionalWitnessBatchLabelLengthRule: RegionalWitnessBatchRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: RegionalWitnessBatch) -> [String] {
            let size = item.label.count
            if size > maxLength {
                return ["label is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class RegionalWitnessBatchUpdatedAtRangeRule: RegionalWitnessBatchRule {
        var min: Int
        var max: Int

        init(min: Int, max: Int) {
            self.min = min
            self.max = max
        }

        func check(_ item: RegionalWitnessBatch) -> [String] {
            let value = item.updatedAt
            var problems: [String] = []
            if value < min {
                problems.append("updated at \(value) is below \(min)")
            }
            if value > max {
                problems.append("updated at \(value) is above \(max)")
            }
            return problems
        }
    }

    final class RegionalWitnessBatchCountryLengthRule: RegionalWitnessBatchRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: RegionalWitnessBatch) -> [String] {
            let size = item.country.count
            if size > maxLength {
                return ["country is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class RegionalWitnessBatchBatchSizeRangeRule: RegionalWitnessBatchRule {
        var min: Int
        var max: Int

        init(min: Int, max: Int) {
            self.min = min
            self.max = max
        }

        func check(_ item: RegionalWitnessBatch) -> [String] {
            let value = item.batchSize
            if value < min || value > max {
                return ["batch size \(value) is outside \(min) to \(max)"]
            }
            return []
        }
    }

    final class RegionalWitnessBatchQuantityRangeRule: RegionalWitnessBatchRule {
        var min: Int
        var max: Int

        init(min: Int, max: Int) {
            self.min = min
            self.max = max
        }

        func check(_ item: RegionalWitnessBatch) -> [String] {
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

    /// Runs every rule of a regional witness batch.
    final class RegionalWitnessBatchValidator {
        var rules: [any RegionalWitnessBatchRule]

        init(rules: [any RegionalWitnessBatchRule]) {
            self.rules = rules
        }

        func validate(_ item: RegionalWitnessBatch) -> [String] {
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

        func requireValid(_ item: RegionalWitnessBatch) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.displayLabel()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [RegionalWitnessBatch]) -> [String: [String]] {
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

    static func defaultRegionalWitnessBatchValidator() -> RegionalWitnessBatchValidator {
        return RegionalWitnessBatchValidator(
            rules: [
                RegionalWitnessBatchLabelLengthRule(maxLength: 3600),
                RegionalWitnessBatchUpdatedAtRangeRule(min: 255, max: 86400),
                RegionalWitnessBatchCountryLengthRule(maxLength: 255),
                RegionalWitnessBatchBatchSizeRangeRule(min: 32, max: 32),
                RegionalWitnessBatchQuantityRangeRule(min: 16, max: 64),
            ]
        )
    }
}
