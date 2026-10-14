import AcmePlatform
import Foundation

extension Pharmacy {
    /// A rule a dispense entry must pass. Check returns its problems, or none.
    protocol DispenseEntryRule {
        func check(_ item: DispenseEntry) -> [String]
    }

    final class DispenseEntryTitleLengthRule: DispenseEntryRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: DispenseEntry) -> [String] {
            let size = item.title.count
            if size > maxLength {
                return ["title is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class DispenseEntrySpecialtyLengthRule: DispenseEntryRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: DispenseEntry) -> [String] {
            let size = item.specialty.count
            if size > maxLength {
                return ["specialty is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class DispenseEntryThresholdRangeRule: DispenseEntryRule {
        var min: Double
        var max: Double

        init(min: Double, max: Double) {
            self.min = min
            self.max = max
        }

        func check(_ item: DispenseEntry) -> [String] {
            let value = item.threshold
            var problems: [String] = []
            if value < min {
                problems.append("threshold \(value) is below \(min)")
            }
            if value > max {
                problems.append("threshold \(value) is above \(max)")
            }
            return problems
        }
    }

    /// Runs every rule of a dispense entry.
    final class DispenseEntryValidator {
        var rules: [any DispenseEntryRule]

        init(rules: [any DispenseEntryRule]) {
            self.rules = rules
        }

        func validate(_ item: DispenseEntry) -> [String] {
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

        func requireValid(_ item: DispenseEntry) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.label()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [DispenseEntry]) -> [String: [String]] {
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

    static func defaultDispenseEntryValidator() -> DispenseEntryValidator {
        return DispenseEntryValidator(
            rules: [
                DispenseEntryTitleLengthRule(maxLength: 1000),
                DispenseEntrySpecialtyLengthRule(maxLength: 120),
                DispenseEntryThresholdRangeRule(min: 2.3, max: 866.6),
            ]
        )
    }
}
