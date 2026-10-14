import AcmePlatform
import Foundation

extension BedManagement {
    /// A rule a capped census baseline must pass. Check returns its problems, or none.
    protocol CappedCensusBaselineRule {
        func check(_ item: CappedCensusBaseline) -> [String]
    }

    final class CappedCensusBaselineCopayRangeRule: CappedCensusBaselineRule {
        var min: Double
        var max: Double

        init(min: Double, max: Double) {
            self.min = min
            self.max = max
        }

        func check(_ item: CappedCensusBaseline) -> [String] {
            let value = item.copay
            if value < min || value > max {
                return ["copay \(value) is outside \(min) to \(max)"]
            }
            return []
        }
    }

    final class CappedCensusBaselineCodeLengthRule: CappedCensusBaselineRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: CappedCensusBaseline) -> [String] {
            let size = item.code.count
            if size > maxLength {
                return ["code is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class CappedCensusBaselineTagsLimitRule: CappedCensusBaselineRule {
        var maxCount: Int
        var banned: [String]

        init(maxCount: Int, banned: [String]) {
            self.maxCount = maxCount
            self.banned = banned
        }

        func check(_ item: CappedCensusBaseline) -> [String] {
            var problems: [String] = []
            if item.tags.count > maxCount {
                problems.append("has \(item.tags.count) tags, at most \(maxCount) allowed")
            }
            for tag in item.tags {
                if banned.contains(tag) {
                    problems.append("tag \(tag) is not allowed")
                }
            }
            return problems
        }
    }

    /// Runs every rule of a capped census baseline.
    final class CappedCensusBaselineValidator {
        var rules: [any CappedCensusBaselineRule]

        init(rules: [any CappedCensusBaselineRule]) {
            self.rules = rules
        }

        func validate(_ item: CappedCensusBaseline) -> [String] {
            var problems: [String] = []
            for rule in rules {
                for problem in rule.check(item) {
                    problems.append(problem)
                }
            }
            return problems
        }

        func requireValid(_ item: CappedCensusBaseline) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.label()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [CappedCensusBaseline]) -> [String: [String]] {
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

    static func defaultCappedCensusBaselineValidator() -> CappedCensusBaselineValidator {
        return CappedCensusBaselineValidator(
            rules: [
                CappedCensusBaselineCopayRangeRule(min: 5.6, max: 1712.6),
                CappedCensusBaselineCodeLengthRule(maxLength: 1000),
                CappedCensusBaselineTagsLimitRule(maxCount: 1000, banned: ["scheduled"]),
            ]
        )
    }
}
