import AcmePlatform
import Foundation

extension Labs {
    /// A rule a result agreement must pass. Check returns its problems, or none.
    protocol ResultAgreementRule {
        func check(_ item: ResultAgreement) -> [String]
    }

    final class ResultAgreementCopayRangeRule: ResultAgreementRule {
        var min: Double
        var max: Double

        init(min: Double, max: Double) {
            self.min = min
            self.max = max
        }

        func check(_ item: ResultAgreement) -> [String] {
            let value = item.copay
            var problems: [String] = []
            if value < min {
                problems.append("copay \(value) is below \(min)")
            }
            if value > max {
                problems.append("copay \(value) is above \(max)")
            }
            return problems
        }
    }

    final class ResultAgreementTitleLengthRule: ResultAgreementRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: ResultAgreement) -> [String] {
            let size = item.title.count
            if size > maxLength {
                return ["title is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class ResultAgreementAllowedTitleRule: ResultAgreementRule {
        var allowed: [String]

        init(allowed: [String]) {
            self.allowed = allowed
        }

        func check(_ item: ResultAgreement) -> [String] {
            if allowed.count == 0 {
                return []
            }
            if !allowed.contains(Kit.Text.normalize(item.title)) {
                return ["title \(item.title) is out of range"]
            }
            return []
        }
    }

    final class ResultAgreementRequiredCodeRule: ResultAgreementRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: ResultAgreement) -> [String] {
            if item.code.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class ResultAgreementRequiredTitleRule: ResultAgreementRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: ResultAgreement) -> [String] {
            if item.title.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class ResultAgreementCapacityRangeRule: ResultAgreementRule {
        var min: Int
        var max: Int

        init(min: Int, max: Int) {
            self.min = min
            self.max = max
        }

        func check(_ item: ResultAgreement) -> [String] {
            let value = item.capacity
            var problems: [String] = []
            if value < min {
                problems.append("capacity \(value) is below \(min)")
            }
            if value > max {
                problems.append("capacity \(value) is above \(max)")
            }
            return problems
        }
    }

    /// Runs every rule of a result agreement.
    final class ResultAgreementValidator {
        var rules: [any ResultAgreementRule]

        init(rules: [any ResultAgreementRule]) {
            self.rules = rules
        }

        func validate(_ item: ResultAgreement) -> [String] {
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

        func requireValid(_ item: ResultAgreement) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.label()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [ResultAgreement]) -> [String: [String]] {
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

    static func defaultResultAgreementValidator() -> ResultAgreementValidator {
        return ResultAgreementValidator(
            rules: [
                ResultAgreementCopayRangeRule(min: 2.1, max: 360.8),
                ResultAgreementTitleLengthRule(maxLength: 32),
                ResultAgreementAllowedTitleRule(allowed: []),
                ResultAgreementRequiredCodeRule(message: "result agreement needs an entry"),
                ResultAgreementRequiredTitleRule(message: "result agreement needs an entry"),
                ResultAgreementCapacityRangeRule(min: 16, max: 120),
            ]
        )
    }
}
