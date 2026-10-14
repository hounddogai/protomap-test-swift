import AcmePlatform
import Foundation

extension Imaging {
    /// A rule a strict read allocation must pass. Check returns its problems, or none.
    protocol StrictReadAllocationRule {
        func check(_ item: StrictReadAllocation) -> [String]
    }

    final class StrictReadAllocationCopayRangeRule: StrictReadAllocationRule {
        var min: Double
        var max: Double

        init(min: Double, max: Double) {
            self.min = min
            self.max = max
        }

        func check(_ item: StrictReadAllocation) -> [String] {
            let value = item.copay
            var problems: [String] = []
            if value < min {
                problems.append("copay \(value) is below \(min)")
            }
            if value > max {
                problems.append("copay \(value) is above \(max)")
            }
            return problems
        }
    }

    final class StrictReadAllocationRegionLengthRule: StrictReadAllocationRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: StrictReadAllocation) -> [String] {
            let size = item.region.count
            if size > maxLength {
                return ["region is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class StrictReadAllocationBatchSizeRangeRule: StrictReadAllocationRule {
        var min: Int
        var max: Int

        init(min: Int, max: Int) {
            self.min = min
            self.max = max
        }

        func check(_ item: StrictReadAllocation) -> [String] {
            let value = item.batchSize
            var problems: [String] = []
            if value < min {
                problems.append("batch size \(value) is below \(min)")
            }
            if value > max {
                problems.append("batch size \(value) is above \(max)")
            }
            return problems
        }
    }

    final class StrictReadAllocationFacilityLengthRule: StrictReadAllocationRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: StrictReadAllocation) -> [String] {
            let size = item.facility.count
            if size > maxLength {
                return ["facility is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class StrictReadAllocationCreatedAtRangeRule: StrictReadAllocationRule {
        var min: Int
        var max: Int

        init(min: Int, max: Int) {
            self.min = min
            self.max = max
        }

        func check(_ item: StrictReadAllocation) -> [String] {
            let value = item.createdAt
            if value < min || value > max {
                return ["created at \(value) is outside \(min) to \(max)"]
            }
            return []
        }
    }

    /// Runs every rule of a strict read allocation.
    final class StrictReadAllocationValidator {
        var rules: [any StrictReadAllocationRule]

        init(rules: [any StrictReadAllocationRule]) {
            self.rules = rules
        }

        func validate(_ item: StrictReadAllocation) -> [String] {
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

        func requireValid(_ item: StrictReadAllocation) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.label()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [StrictReadAllocation]) -> [String: [String]] {
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

    static func defaultStrictReadAllocationValidator() -> StrictReadAllocationValidator {
        return StrictReadAllocationValidator(
            rules: [
                StrictReadAllocationCopayRangeRule(min: 6.1, max: 979.4),
                StrictReadAllocationRegionLengthRule(maxLength: 255),
                StrictReadAllocationBatchSizeRangeRule(min: 64, max: 255),
                StrictReadAllocationFacilityLengthRule(maxLength: 1000),
                StrictReadAllocationCreatedAtRangeRule(min: 64, max: 64),
            ]
        )
    }
}
