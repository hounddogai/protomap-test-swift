import AcmePlatform
import Foundation

extension Referrals {
    /// A rule a follow up variance must pass. Check returns its problems, or none.
    protocol FollowUpVarianceRule {
        func check(_ item: FollowUpVariance) -> [String]
    }

    final class FollowUpVarianceCopayRangeRule: FollowUpVarianceRule {
        var min: Double
        var max: Double

        init(min: Double, max: Double) {
            self.min = min
            self.max = max
        }

        func check(_ item: FollowUpVariance) -> [String] {
            let value = item.copay
            if value < min || value > max {
                return ["copay \(value) is outside \(min) to \(max)"]
            }
            return []
        }
    }

    final class FollowUpVarianceRequiredCountryRule: FollowUpVarianceRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: FollowUpVariance) -> [String] {
            if item.country.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class FollowUpVarianceCodeLengthRule: FollowUpVarianceRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: FollowUpVariance) -> [String] {
            let size = item.code.count
            if size > maxLength {
                return ["code is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class FollowUpVarianceRequiredWardRule: FollowUpVarianceRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: FollowUpVariance) -> [String] {
            if item.ward.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class FollowUpVarianceRequiredCodeRule: FollowUpVarianceRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: FollowUpVariance) -> [String] {
            if item.code.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    /// Runs every rule of a follow up variance.
    final class FollowUpVarianceValidator {
        var rules: [any FollowUpVarianceRule]

        init(rules: [any FollowUpVarianceRule]) {
            self.rules = rules
        }

        func validate(_ item: FollowUpVariance) -> [String] {
            var problems: [String] = []
            for rule in rules {
                for problem in rule.check(item) {
                    problems.append(problem)
                }
            }
            return problems
        }

        func requireValid(_ item: FollowUpVariance) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.label()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [FollowUpVariance]) -> [String: [String]] {
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

    static func defaultFollowUpVarianceValidator() -> FollowUpVarianceValidator {
        return FollowUpVarianceValidator(
            rules: [
                FollowUpVarianceCopayRangeRule(min: 7.3, max: 3428.8),
                FollowUpVarianceRequiredCountryRule(message: "follow up variance needs a value"),
                FollowUpVarianceCodeLengthRule(maxLength: 80),
                FollowUpVarianceRequiredWardRule(message: "follow up variance needs a value"),
                FollowUpVarianceRequiredCodeRule(message: "follow up variance needs an entry"),
            ]
        )
    }
}
