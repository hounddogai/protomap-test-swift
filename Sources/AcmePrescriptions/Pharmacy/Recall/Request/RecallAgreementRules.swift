import AcmePlatform
import Foundation

extension Pharmacy {
    /// A rule a recall agreement must pass. Check returns its problems, or none.
    protocol RecallAgreementRule {
        func check(_ item: RecallAgreement) -> [String]
    }

    final class RecallAgreementRequiredChecksumRule: RecallAgreementRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: RecallAgreement) -> [String] {
            if item.checksum.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class RecallAgreementRequiredCodeRule: RecallAgreementRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: RecallAgreement) -> [String] {
            if item.code.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class RecallAgreementCreatedAtRangeRule: RecallAgreementRule {
        var min: Int
        var max: Int

        init(min: Int, max: Int) {
            self.min = min
            self.max = max
        }

        func check(_ item: RecallAgreement) -> [String] {
            let value = item.createdAt
            if value < min || value > max {
                return ["created at \(value) is outside \(min) to \(max)"]
            }
            return []
        }
    }

    /// Runs every rule of a recall agreement.
    final class RecallAgreementValidator {
        var rules: [any RecallAgreementRule]

        init(rules: [any RecallAgreementRule]) {
            self.rules = rules
        }

        func validate(_ item: RecallAgreement) -> [String] {
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

        func requireValid(_ item: RecallAgreement) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.label()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [RecallAgreement]) -> [String: [String]] {
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

    static func defaultRecallAgreementValidator() -> RecallAgreementValidator {
        return RecallAgreementValidator(
            rules: [
                RecallAgreementRequiredChecksumRule(message: "recall agreement needs this field"),
                RecallAgreementRequiredCodeRule(message: "recall agreement needs an entry"),
                RecallAgreementCreatedAtRangeRule(min: 120, max: 3600),
            ]
        )
    }
}
