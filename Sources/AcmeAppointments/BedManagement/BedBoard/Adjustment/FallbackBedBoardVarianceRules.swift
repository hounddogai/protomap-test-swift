import AcmePlatform
import Foundation

extension BedManagement {
    /// A rule a fallback bed board variance must pass. Check returns its problems, or none.
    protocol FallbackBedBoardVarianceRule {
        func check(_ item: FallbackBedBoardVariance) -> [String]
    }

    final class FallbackBedBoardVarianceArchivedGuardRule: FallbackBedBoardVarianceRule {
        var limit: Double

        init(limit: Double) {
            self.limit = limit
        }

        func check(_ item: FallbackBedBoardVariance) -> [String] {
            if item.archived && (item.amount > limit) {
                return ["amount \(item.amount) exceeds \(limit) while archived"]
            }
            return []
        }
    }

    final class FallbackBedBoardVarianceSegmentLengthRule: FallbackBedBoardVarianceRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: FallbackBedBoardVariance) -> [String] {
            let size = item.segment.count
            if size > maxLength {
                return ["segment is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class FallbackBedBoardVarianceCodeLengthRule: FallbackBedBoardVarianceRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: FallbackBedBoardVariance) -> [String] {
            let size = item.code.count
            if size > maxLength {
                return ["code is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class FallbackBedBoardVarianceAmountRangeRule: FallbackBedBoardVarianceRule {
        var min: Double
        var max: Double

        init(min: Double, max: Double) {
            self.min = min
            self.max = max
        }

        func check(_ item: FallbackBedBoardVariance) -> [String] {
            let value = item.amount
            var problems: [String] = []
            if value < min {
                problems.append("amount \(value) is below \(min)")
            }
            if value > max {
                problems.append("amount \(value) is above \(max)")
            }
            return problems
        }
    }

    /// Runs every rule of a fallback bed board variance.
    final class FallbackBedBoardVarianceValidator {
        var rules: [any FallbackBedBoardVarianceRule]

        init(rules: [any FallbackBedBoardVarianceRule]) {
            self.rules = rules
        }

        func validate(_ item: FallbackBedBoardVariance) -> [String] {
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

        func requireValid(_ item: FallbackBedBoardVariance) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.label()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [FallbackBedBoardVariance]) -> [String: [String]] {
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

    static func defaultFallbackBedBoardVarianceValidator() -> FallbackBedBoardVarianceValidator {
        return FallbackBedBoardVarianceValidator(
            rules: [
                FallbackBedBoardVarianceArchivedGuardRule(limit: 3.7),
                FallbackBedBoardVarianceSegmentLengthRule(maxLength: 32),
                FallbackBedBoardVarianceCodeLengthRule(maxLength: 16),
                FallbackBedBoardVarianceAmountRangeRule(min: 8.0, max: 1342.0),
            ]
        )
    }
}
