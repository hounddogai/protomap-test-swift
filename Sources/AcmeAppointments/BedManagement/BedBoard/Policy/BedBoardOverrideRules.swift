import AcmePlatform
import Foundation

extension BedManagement {
    /// A rule a bed board override must pass. Check returns its problems, or none.
    protocol BedBoardOverrideRule {
        func check(_ item: BedBoardOverride) -> [String]
    }

    final class BedBoardOverrideCopayRangeRule: BedBoardOverrideRule {
        var min: Double
        var max: Double

        init(min: Double, max: Double) {
            self.min = min
            self.max = max
        }

        func check(_ item: BedBoardOverride) -> [String] {
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

    final class BedBoardOverrideCodeLengthRule: BedBoardOverrideRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: BedBoardOverride) -> [String] {
            let size = item.code.count
            if size > maxLength {
                return ["code is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class BedBoardOverrideThresholdRangeRule: BedBoardOverrideRule {
        var min: Double
        var max: Double

        init(min: Double, max: Double) {
            self.min = min
            self.max = max
        }

        func check(_ item: BedBoardOverride) -> [String] {
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

    /// Runs every rule of a bed board override.
    final class BedBoardOverrideValidator {
        var rules: [any BedBoardOverrideRule]

        init(rules: [any BedBoardOverrideRule]) {
            self.rules = rules
        }

        func validate(_ item: BedBoardOverride) -> [String] {
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

        func requireValid(_ item: BedBoardOverride) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.label()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [BedBoardOverride]) -> [String: [String]] {
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

    static func defaultBedBoardOverrideValidator() -> BedBoardOverrideValidator {
        return BedBoardOverrideValidator(
            rules: [
                BedBoardOverrideCopayRangeRule(min: 2.3, max: 3662.0),
                BedBoardOverrideCodeLengthRule(maxLength: 3600),
                BedBoardOverrideThresholdRangeRule(min: 10.0, max: 3001.3),
            ]
        )
    }
}
