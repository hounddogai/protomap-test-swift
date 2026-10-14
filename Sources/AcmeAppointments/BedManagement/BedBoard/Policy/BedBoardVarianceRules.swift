import AcmePlatform
import Foundation

extension BedManagement {
    /// A rule a bed board variance must pass. Check returns its problems, or none.
    protocol BedBoardVarianceRule {
        func check(_ item: BedBoardVariance) -> [String]
    }

    final class BedBoardVarianceApprovedGuardRule: BedBoardVarianceRule {
        var limit: Double

        init(limit: Double) {
            self.limit = limit
        }

        func check(_ item: BedBoardVariance) -> [String] {
            if item.approved && (item.minimum > limit) {
                return ["minimum \(item.minimum) exceeds \(limit) while approved"]
            }
            return []
        }
    }

    final class BedBoardVarianceLimitRangeRule: BedBoardVarianceRule {
        var min: Int
        var max: Int

        init(min: Int, max: Int) {
            self.min = min
            self.max = max
        }

        func check(_ item: BedBoardVariance) -> [String] {
            let value = item.limit
            var problems: [String] = []
            if value < min {
                problems.append("limit \(value) is below \(min)")
            }
            if value > max {
                problems.append("limit \(value) is above \(max)")
            }
            return problems
        }
    }

    final class BedBoardVarianceAllowedTitleRule: BedBoardVarianceRule {
        var allowed: [String]

        init(allowed: [String]) {
            self.allowed = allowed
        }

        func check(_ item: BedBoardVariance) -> [String] {
            if allowed.count == 0 {
                return []
            }
            if !allowed.contains(Kit.Text.normalize(item.title)) {
                return ["title \(item.title) is not allowed"]
            }
            return []
        }
    }

    /// Runs every rule of a bed board variance.
    final class BedBoardVarianceValidator {
        var rules: [any BedBoardVarianceRule]

        init(rules: [any BedBoardVarianceRule]) {
            self.rules = rules
        }

        func validate(_ item: BedBoardVariance) -> [String] {
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

        func requireValid(_ item: BedBoardVariance) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.label()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [BedBoardVariance]) -> [String: [String]] {
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

    static func defaultBedBoardVarianceValidator() -> BedBoardVarianceValidator {
        return BedBoardVarianceValidator(
            rules: [
                BedBoardVarianceApprovedGuardRule(limit: 1.3),
                BedBoardVarianceLimitRangeRule(min: 16, max: 16),
                BedBoardVarianceAllowedTitleRule(allowed: []),
            ]
        )
    }
}
