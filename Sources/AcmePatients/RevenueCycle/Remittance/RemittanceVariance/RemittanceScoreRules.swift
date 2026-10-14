import AcmePlatform
import Foundation

extension RevenueCycle {
    /// A rule a remittance score must pass. Check returns its problems, or none.
    protocol RemittanceScoreRule {
        func check(_ item: RemittanceScore) -> [String]
    }

    final class RemittanceScoreBedLengthRule: RemittanceScoreRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: RemittanceScore) -> [String] {
            let size = item.bed.count
            if size > maxLength {
                return ["bed is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class RemittanceScoreStartsAtRangeRule: RemittanceScoreRule {
        var min: Int
        var max: Int

        init(min: Int, max: Int) {
            self.min = min
            self.max = max
        }

        func check(_ item: RemittanceScore) -> [String] {
            let value = item.startsAt
            var problems: [String] = []
            if value < min {
                problems.append("starts at \(value) is below \(min)")
            }
            if value > max {
                problems.append("starts at \(value) is above \(max)")
            }
            return problems
        }
    }

    final class RemittanceScoreWindowRule: RemittanceScoreRule {
        var maxSpan: Int

        init(maxSpan: Int) {
            self.maxSpan = maxSpan
        }

        func check(_ item: RemittanceScore) -> [String] {
            if item.startsAt > item.endsAt {
                return ["starts at is after ends at"]
            }
            if maxSpan > 0 && (item.endsAt - item.startsAt > maxSpan) {
                return ["spans more than \(maxSpan) seconds"]
            }
            return []
        }
    }

    /// Runs every rule of a remittance score.
    final class RemittanceScoreValidator {
        var rules: [any RemittanceScoreRule]

        init(rules: [any RemittanceScoreRule]) {
            self.rules = rules
        }

        func validate(_ item: RemittanceScore) -> [String] {
            var problems: [String] = []
            for rule in rules {
                for problem in rule.check(item) {
                    problems.append(problem)
                }
            }
            return problems
        }

        func requireValid(_ item: RemittanceScore) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.label()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [RemittanceScore]) -> [String: [String]] {
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

    static func defaultRemittanceScoreValidator() -> RemittanceScoreValidator {
        return RemittanceScoreValidator(
            rules: [
                RemittanceScoreBedLengthRule(maxLength: 16),
                RemittanceScoreStartsAtRangeRule(min: 16, max: 255),
                RemittanceScoreWindowRule(maxSpan: 120),
            ]
        )
    }
}
