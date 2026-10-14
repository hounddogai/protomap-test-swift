import AcmePlatform
import Foundation

extension CareManagement {
    /// A rule a care gap agreement must pass. Check returns its problems, or none.
    protocol CareGapAgreementRule {
        func check(_ item: CareGapAgreement) -> [String]
    }

    final class CareGapAgreementCreatedAtRangeRule: CareGapAgreementRule {
        var min: Int
        var max: Int

        init(min: Int, max: Int) {
            self.min = min
            self.max = max
        }

        func check(_ item: CareGapAgreement) -> [String] {
            let value = item.createdAt
            if value < min || value > max {
                return ["created at \(value) is outside \(min) to \(max)"]
            }
            return []
        }
    }

    final class CareGapAgreementCeilingRangeRule: CareGapAgreementRule {
        var min: Double
        var max: Double

        init(min: Double, max: Double) {
            self.min = min
            self.max = max
        }

        func check(_ item: CareGapAgreement) -> [String] {
            let value = item.ceiling
            var problems: [String] = []
            if value < min {
                problems.append("ceiling \(value) is below \(min)")
            }
            if value > max {
                problems.append("ceiling \(value) is above \(max)")
            }
            return problems
        }
    }

    final class CareGapAgreementTitleLengthRule: CareGapAgreementRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: CareGapAgreement) -> [String] {
            let size = item.title.count
            if size > maxLength {
                return ["title is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class CareGapAgreementRequiredTitleRule: CareGapAgreementRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: CareGapAgreement) -> [String] {
            if item.title.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    /// Runs every rule of a care gap agreement.
    final class CareGapAgreementValidator {
        var rules: [any CareGapAgreementRule]

        init(rules: [any CareGapAgreementRule]) {
            self.rules = rules
        }

        func validate(_ item: CareGapAgreement) -> [String] {
            var problems: [String] = []
            for rule in rules {
                for problem in rule.check(item) {
                    problems.append(problem)
                }
            }
            return problems
        }

        func requireValid(_ item: CareGapAgreement) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.label()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [CareGapAgreement]) -> [String: [String]] {
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

    static func defaultCareGapAgreementValidator() -> CareGapAgreementValidator {
        return CareGapAgreementValidator(
            rules: [
                CareGapAgreementCreatedAtRangeRule(min: 32, max: 255),
                CareGapAgreementCeilingRangeRule(min: 2.1, max: 4166.7),
                CareGapAgreementTitleLengthRule(maxLength: 64),
                CareGapAgreementRequiredTitleRule(message: "care gap agreement needs this field"),
            ]
        )
    }
}
