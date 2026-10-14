import AcmePlatform
import Foundation

extension ClinicalOps {
    /// A rule a care protocol score must pass. Check returns its problems, or none.
    protocol CareProtocolScoreRule {
        func check(_ item: CareProtocolScore) -> [String]
    }

    final class CareProtocolScoreProcedureCodeLengthRule: CareProtocolScoreRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: CareProtocolScore) -> [String] {
            let size = item.procedureCode.count
            if size > maxLength {
                return ["procedure code is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
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

    final class CareProtocolScoreRequiredTitleRule: CareProtocolScoreRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: CareProtocolScore) -> [String] {
            if item.title.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
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
                for problem in rule.check(item) {
                    problems.append(problem)
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
                CareProtocolScoreProcedureCodeLengthRule(maxLength: 86400),
                CareProtocolScoreBudgetRangeRule(min: 7.3, max: 4266.6),
                CareProtocolScoreRequiredTitleRule(message: "care protocol score needs an entry"),
            ]
        )
    }
}
