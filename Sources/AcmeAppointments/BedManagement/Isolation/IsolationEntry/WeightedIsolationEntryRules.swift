import AcmePlatform
import Foundation

extension BedManagement {
    /// A rule a weighted isolation entry must pass. Check returns its problems, or none.
    protocol WeightedIsolationEntryRule {
        func check(_ item: WeightedIsolationEntry) -> [String]
    }

    final class WeightedIsolationEntryNameLengthRule: WeightedIsolationEntryRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: WeightedIsolationEntry) -> [String] {
            let size = item.name.count
            if size > maxLength {
                return ["name is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class WeightedIsolationEntryApprovedGuardRule: WeightedIsolationEntryRule {
        var limit: Double

        init(limit: Double) {
            self.limit = limit
        }

        func check(_ item: WeightedIsolationEntry) -> [String] {
            if item.approved && (item.ceiling > limit) {
                return ["ceiling \(item.ceiling) exceeds \(limit) while approved"]
            }
            return []
        }
    }

    final class WeightedIsolationEntryLimitRangeRule: WeightedIsolationEntryRule {
        var min: Int
        var max: Int

        init(min: Int, max: Int) {
            self.min = min
            self.max = max
        }

        func check(_ item: WeightedIsolationEntry) -> [String] {
            let value = item.limit
            if value < min || value > max {
                return ["limit \(value) is outside \(min) to \(max)"]
            }
            return []
        }
    }

    final class WeightedIsolationEntryCodeLengthRule: WeightedIsolationEntryRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: WeightedIsolationEntry) -> [String] {
            let size = item.code.count
            if size > maxLength {
                return ["code is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    /// Runs every rule of a weighted isolation entry.
    final class WeightedIsolationEntryValidator {
        var rules: [any WeightedIsolationEntryRule]

        init(rules: [any WeightedIsolationEntryRule]) {
            self.rules = rules
        }

        func validate(_ item: WeightedIsolationEntry) -> [String] {
            var problems: [String] = []
            for rule in rules {
                for problem in rule.check(item) {
                    problems.append(problem)
                }
            }
            return problems
        }

        func requireValid(_ item: WeightedIsolationEntry) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.displayLabel()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [WeightedIsolationEntry]) -> [String: [String]] {
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

    static func defaultWeightedIsolationEntryValidator() -> WeightedIsolationEntryValidator {
        return WeightedIsolationEntryValidator(
            rules: [
                WeightedIsolationEntryNameLengthRule(maxLength: 64),
                WeightedIsolationEntryApprovedGuardRule(limit: 5.9),
                WeightedIsolationEntryLimitRangeRule(min: 64, max: 1000),
                WeightedIsolationEntryCodeLengthRule(maxLength: 16),
            ]
        )
    }
}
