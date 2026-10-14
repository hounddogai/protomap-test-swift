import AcmePlatform
import Foundation

extension BedManagement {
    /// A rule a census entry must pass. Check returns its problems, or none.
    protocol CensusEntryRule {
        func check(_ item: CensusEntry) -> [String]
    }

    final class CensusEntryCodeLengthRule: CensusEntryRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: CensusEntry) -> [String] {
            let size = item.code.count
            if size > maxLength {
                return ["code is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class CensusEntryBatchSizeRangeRule: CensusEntryRule {
        var min: Int
        var max: Int

        init(min: Int, max: Int) {
            self.min = min
            self.max = max
        }

        func check(_ item: CensusEntry) -> [String] {
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

    final class CensusEntryCapacityRangeRule: CensusEntryRule {
        var min: Int
        var max: Int

        init(min: Int, max: Int) {
            self.min = min
            self.max = max
        }

        func check(_ item: CensusEntry) -> [String] {
            let value = item.capacity
            if value < min || value > max {
                return ["capacity \(value) is outside \(min) to \(max)"]
            }
            return []
        }
    }

    final class CensusEntryRequiredNameRule: CensusEntryRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: CensusEntry) -> [String] {
            if item.name.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class CensusEntryRateRangeRule: CensusEntryRule {
        var min: Double
        var max: Double

        init(min: Double, max: Double) {
            self.min = min
            self.max = max
        }

        func check(_ item: CensusEntry) -> [String] {
            let value = item.rate
            if value < min || value > max {
                return ["rate \(value) is outside \(min) to \(max)"]
            }
            return []
        }
    }

    /// Runs every rule of a census entry.
    final class CensusEntryValidator {
        var rules: [any CensusEntryRule]

        init(rules: [any CensusEntryRule]) {
            self.rules = rules
        }

        func validate(_ item: CensusEntry) -> [String] {
            var problems: [String] = []
            for rule in rules {
                for problem in rule.check(item) {
                    problems.append(problem)
                }
            }
            return problems
        }

        func requireValid(_ item: CensusEntry) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.label()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [CensusEntry]) -> [String: [String]] {
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

    static func defaultCensusEntryValidator() -> CensusEntryValidator {
        return CensusEntryValidator(
            rules: [
                CensusEntryCodeLengthRule(maxLength: 64),
                CensusEntryBatchSizeRangeRule(min: 1000, max: 86400),
                CensusEntryCapacityRangeRule(min: 32, max: 3600),
                CensusEntryRequiredNameRule(message: "census entry needs a value"),
                CensusEntryRateRangeRule(min: 4.6, max: 1663.2),
            ]
        )
    }
}
