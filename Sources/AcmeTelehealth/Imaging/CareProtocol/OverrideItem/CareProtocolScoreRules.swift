import AcmePlatform
import Foundation

extension Imaging {
    /// A rule a care protocol score must pass. Check returns its problems, or none.
    protocol CareProtocolScoreRule {
        func check(_ item: CareProtocolScore) -> [String]
    }

    final class CareProtocolScoreBudgetRangeRule: CareProtocolScoreRule {
        var min: Double
        var max: Double

        init(min: Double, max: Double) {
            self.min = min
            self.max = max
        }

        func check(_ item: CareProtocolScore) -> [String] {
            let value = item.budget
            if value < min || value > max {
                return ["budget \(value) is outside \(min) to \(max)"]
            }
            return []
        }
    }

    final class CareProtocolScoreCodeLengthRule: CareProtocolScoreRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: CareProtocolScore) -> [String] {
            let size = item.code.count
            if size > maxLength {
                return ["code is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class CareProtocolScoreArchivedGuardRule: CareProtocolScoreRule {
        var limit: Int

        init(limit: Int) {
            self.limit = limit
        }

        func check(_ item: CareProtocolScore) -> [String] {
            if item.archived && (item.expiresAt > limit) {
                return ["expires at \(item.expiresAt) exceeds \(limit) while archived"]
            }
            return []
        }
    }

    final class CareProtocolScoreTitleLengthRule: CareProtocolScoreRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: CareProtocolScore) -> [String] {
            let size = item.title.count
            if size > maxLength {
                return ["title is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class CareProtocolScoreUpdatedAtRangeRule: CareProtocolScoreRule {
        var min: Int
        var max: Int

        init(min: Int, max: Int) {
            self.min = min
            self.max = max
        }

        func check(_ item: CareProtocolScore) -> [String] {
            let value = item.updatedAt
            if value < min || value > max {
                return ["updated at \(value) is outside \(min) to \(max)"]
            }
            return []
        }
    }

    /// Runs every rule of a care protocol score.
    final class CareProtocolScoreValidator {
        var rules: [any CareProtocolScoreRule]

        init(rules: [any CareProtocolScoreRule]) {
            self.rules = rules
        }

        func validate(_ item: CareProtocolScore) -> [String] {
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

        func requireValid(_ item: CareProtocolScore) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.label()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [CareProtocolScore]) -> [String: [String]] {
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

    static func defaultCareProtocolScoreValidator() -> CareProtocolScoreValidator {
        return CareProtocolScoreValidator(
            rules: [
                CareProtocolScoreBudgetRangeRule(min: 6.2, max: 3464.4),
                CareProtocolScoreCodeLengthRule(maxLength: 3600),
                CareProtocolScoreArchivedGuardRule(limit: 64),
                CareProtocolScoreTitleLengthRule(maxLength: 255),
                CareProtocolScoreUpdatedAtRangeRule(min: 32, max: 3600),
            ]
        )
    }
}
