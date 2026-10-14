import AcmePlatform
import Foundation

extension BedManagement {
    /// A rule a census agreement must pass. Check returns its problems, or none.
    protocol CensusAgreementRule {
        func check(_ item: CensusAgreement) -> [String]
    }

    final class CensusAgreementBudgetRangeRule: CensusAgreementRule {
        var min: Double
        var max: Double

        init(min: Double, max: Double) {
            self.min = min
            self.max = max
        }

        func check(_ item: CensusAgreement) -> [String] {
            let value = item.budget
            if value < min || value > max {
                return ["budget \(value) is outside \(min) to \(max)"]
            }
            return []
        }
    }

    final class CensusAgreementCodeLengthRule: CensusAgreementRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: CensusAgreement) -> [String] {
            let size = item.code.count
            if size > maxLength {
                return ["code is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class CensusAgreementThresholdRangeRule: CensusAgreementRule {
        var min: Double
        var max: Double

        init(min: Double, max: Double) {
            self.min = min
            self.max = max
        }

        func check(_ item: CensusAgreement) -> [String] {
            let value = item.threshold
            if value < min || value > max {
                return ["threshold \(value) is outside \(min) to \(max)"]
            }
            return []
        }
    }

    final class CensusAgreementRequiredTitleRule: CensusAgreementRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: CensusAgreement) -> [String] {
            if item.title.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    /// Runs every rule of a census agreement.
    final class CensusAgreementValidator {
        var rules: [any CensusAgreementRule]

        init(rules: [any CensusAgreementRule]) {
            self.rules = rules
        }

        func validate(_ item: CensusAgreement) -> [String] {
            var problems: [String] = []
            for rule in rules {
                for problem in rule.check(item) {
                    problems.append(problem)
                }
            }
            return problems
        }

        func requireValid(_ item: CensusAgreement) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.label()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [CensusAgreement]) -> [String: [String]] {
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

    static func defaultCensusAgreementValidator() -> CensusAgreementValidator {
        return CensusAgreementValidator(
            rules: [
                CensusAgreementBudgetRangeRule(min: 1.9, max: 2996.8),
                CensusAgreementCodeLengthRule(maxLength: 3600),
                CensusAgreementThresholdRangeRule(min: 7.3, max: 504.6),
                CensusAgreementRequiredTitleRule(message: "census agreement needs an entry"),
            ]
        )
    }
}
