import AcmePlatform
import Foundation

extension CareManagement {
    /// A rule a global outreach agreement must pass. Check returns its problems, or none.
    protocol GlobalOutreachAgreementRule {
        func check(_ item: GlobalOutreachAgreement) -> [String]
    }

    final class GlobalOutreachAgreementTimezoneLengthRule: GlobalOutreachAgreementRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: GlobalOutreachAgreement) -> [String] {
            let size = item.timezone.count
            if size > maxLength {
                return ["timezone is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class GlobalOutreachAgreementRatioRangeRule: GlobalOutreachAgreementRule {
        var min: Double
        var max: Double

        init(min: Double, max: Double) {
            self.min = min
            self.max = max
        }

        func check(_ item: GlobalOutreachAgreement) -> [String] {
            let value = item.ratio
            var problems: [String] = []
            if value < min {
                problems.append("ratio \(value) is below \(min)")
            }
            if value > max {
                problems.append("ratio \(value) is above \(max)")
            }
            return problems
        }
    }

    final class GlobalOutreachAgreementRequiredSourceRule: GlobalOutreachAgreementRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: GlobalOutreachAgreement) -> [String] {
            if item.source.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class GlobalOutreachAgreementRequiredTitleRule: GlobalOutreachAgreementRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: GlobalOutreachAgreement) -> [String] {
            if item.title.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    /// Runs every rule of a global outreach agreement.
    final class GlobalOutreachAgreementValidator {
        var rules: [any GlobalOutreachAgreementRule]

        init(rules: [any GlobalOutreachAgreementRule]) {
            self.rules = rules
        }

        func validate(_ item: GlobalOutreachAgreement) -> [String] {
            var problems: [String] = []
            for rule in rules {
                for problem in rule.check(item) {
                    problems.append(problem)
                }
            }
            return problems
        }

        func requireValid(_ item: GlobalOutreachAgreement) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.label()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [GlobalOutreachAgreement]) -> [String: [String]] {
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

    static func defaultGlobalOutreachAgreementValidator() -> GlobalOutreachAgreementValidator {
        return GlobalOutreachAgreementValidator(
            rules: [
                GlobalOutreachAgreementTimezoneLengthRule(maxLength: 16),
                GlobalOutreachAgreementRatioRangeRule(min: 0.3, max: 1063.5),
                GlobalOutreachAgreementRequiredSourceRule(message: "global outreach agreement needs a value"),
                GlobalOutreachAgreementRequiredTitleRule(message: "global outreach agreement needs a value"),
            ]
        )
    }
}
