import AcmePlatform
import Foundation

extension BedManagement {
    /// A rule a bed board estimate must pass. Check returns its problems, or none.
    protocol BedBoardEstimateRule {
        func check(_ item: BedBoardEstimate) -> [String]
    }

    final class BedBoardEstimateCodePrefixRule: BedBoardEstimateRule {
        var prefix: String

        init(prefix: String) {
            self.prefix = prefix
        }

        func check(_ item: BedBoardEstimate) -> [String] {
            if !item.code.uppercased().hasPrefix(prefix.uppercased()) {
                return ["code must start with \(prefix)"]
            }
            return []
        }
    }

    final class BedBoardEstimateMarginRangeRule: BedBoardEstimateRule {
        var min: Double
        var max: Double

        init(min: Double, max: Double) {
            self.min = min
            self.max = max
        }

        func check(_ item: BedBoardEstimate) -> [String] {
            let value = item.margin
            var problems: [String] = []
            if value < min {
                problems.append("margin \(value) is below \(min)")
            }
            if value > max {
                problems.append("margin \(value) is above \(max)")
            }
            return problems
        }
    }

    final class BedBoardEstimateCodeLengthRule: BedBoardEstimateRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: BedBoardEstimate) -> [String] {
            let size = item.code.count
            if size > maxLength {
                return ["code is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    /// Runs every rule of a bed board estimate.
    final class BedBoardEstimateValidator {
        var rules: [any BedBoardEstimateRule]

        init(rules: [any BedBoardEstimateRule]) {
            self.rules = rules
        }

        func validate(_ item: BedBoardEstimate) -> [String] {
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

        func requireValid(_ item: BedBoardEstimate) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.displayLabel()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [BedBoardEstimate]) -> [String: [String]] {
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

    static func defaultBedBoardEstimateValidator() -> BedBoardEstimateValidator {
        return BedBoardEstimateValidator(
            rules: [
                BedBoardEstimateCodePrefixRule(prefix: "Q"),
                BedBoardEstimateMarginRangeRule(min: 0.5, max: 2745.1),
                BedBoardEstimateCodeLengthRule(maxLength: 32),
            ]
        )
    }
}
