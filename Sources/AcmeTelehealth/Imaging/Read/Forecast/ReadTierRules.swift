import AcmePlatform
import Foundation

extension Imaging {
    /// A rule a read tier must pass. Check returns its problems, or none.
    protocol ReadTierRule {
        func check(_ item: ReadTier) -> [String]
    }

    final class ReadTierRetriesRangeRule: ReadTierRule {
        var min: Int
        var max: Int

        init(min: Int, max: Int) {
            self.min = min
            self.max = max
        }

        func check(_ item: ReadTier) -> [String] {
            let value = item.retries
            var problems: [String] = []
            if value < min {
                problems.append("retries \(value) is below \(min)")
            }
            if value > max {
                problems.append("retries \(value) is above \(max)")
            }
            return problems
        }
    }

    final class ReadTierRequiredCodeRule: ReadTierRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: ReadTier) -> [String] {
            if item.code.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class ReadTierFloorValueRangeRule: ReadTierRule {
        var min: Double
        var max: Double

        init(min: Double, max: Double) {
            self.min = min
            self.max = max
        }

        func check(_ item: ReadTier) -> [String] {
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

    /// Runs every rule of a read tier.
    final class ReadTierValidator {
        var rules: [any ReadTierRule]

        init(rules: [any ReadTierRule]) {
            self.rules = rules
        }

        func validate(_ item: ReadTier) -> [String] {
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

        func requireValid(_ item: ReadTier) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.displayLabel()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [ReadTier]) -> [String: [String]] {
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

    static func defaultReadTierValidator() -> ReadTierValidator {
        return ReadTierValidator(
            rules: [
                ReadTierRetriesRangeRule(min: 16, max: 3600),
                ReadTierRequiredCodeRule(message: "read tier needs an entry"),
                ReadTierFloorValueRangeRule(min: 6.6, max: 616.7),
            ]
        )
    }
}
