import AcmePlatform
import Foundation

extension Imaging {
    /// A rule a capped care protocol score must pass. Check returns its problems, or none.
    protocol CappedCareProtocolScoreRule {
        func check(_ item: CappedCareProtocolScore) -> [String]
    }

    final class CappedCareProtocolScoreDiagnosisCodeLengthRule: CappedCareProtocolScoreRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: CappedCareProtocolScore) -> [String] {
            let size = item.diagnosisCode.count
            if size > maxLength {
                return ["diagnosis code is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class CappedCareProtocolScoreAttemptsRangeRule: CappedCareProtocolScoreRule {
        var min: Int
        var max: Int

        init(min: Int, max: Int) {
            self.min = min
            self.max = max
        }

        func check(_ item: CappedCareProtocolScore) -> [String] {
            let value = item.attempts
            var problems: [String] = []
            if value < min {
                problems.append("attempts \(value) is below \(min)")
            }
            if value > max {
                problems.append("attempts \(value) is above \(max)")
            }
            return problems
        }
    }

    final class CappedCareProtocolScoreAllowedSummaryRule: CappedCareProtocolScoreRule {
        var allowed: [String]

        init(allowed: [String]) {
            self.allowed = allowed
        }

        func check(_ item: CappedCareProtocolScore) -> [String] {
            if allowed.count == 0 {
                return []
            }
            if !allowed.contains(Kit.Text.normalize(item.summary)) {
                return ["summary \(item.summary) is above maximum"]
            }
            return []
        }
    }

    final class CappedCareProtocolScoreTitleLengthRule: CappedCareProtocolScoreRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: CappedCareProtocolScore) -> [String] {
            let size = item.title.count
            if size > maxLength {
                return ["title is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    /// Runs every rule of a capped care protocol score.
    final class CappedCareProtocolScoreValidator {
        var rules: [any CappedCareProtocolScoreRule]

        init(rules: [any CappedCareProtocolScoreRule]) {
            self.rules = rules
        }

        func validate(_ item: CappedCareProtocolScore) -> [String] {
            var problems: [String] = []
            for rule in rules {
                for problem in rule.check(item) {
                    problems.append(problem)
                }
            }
            return problems
        }

        func requireValid(_ item: CappedCareProtocolScore) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.label()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [CappedCareProtocolScore]) -> [String: [String]] {
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

    static func defaultCappedCareProtocolScoreValidator() -> CappedCareProtocolScoreValidator {
        return CappedCareProtocolScoreValidator(
            rules: [
                CappedCareProtocolScoreDiagnosisCodeLengthRule(maxLength: 80),
                CappedCareProtocolScoreAttemptsRangeRule(min: 64, max: 1000),
                CappedCareProtocolScoreAllowedSummaryRule(allowed: []),
                CappedCareProtocolScoreTitleLengthRule(maxLength: 64),
            ]
        )
    }
}
