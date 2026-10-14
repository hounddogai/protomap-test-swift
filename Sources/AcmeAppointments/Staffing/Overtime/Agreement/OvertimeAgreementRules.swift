import AcmePlatform
import Foundation

extension Staffing {
    /// A rule a overtime agreement must pass. Check returns its problems, or none.
    protocol OvertimeAgreementRule {
        func check(_ item: OvertimeAgreement) -> [String]
    }

    final class OvertimeAgreementCodeLengthRule: OvertimeAgreementRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: OvertimeAgreement) -> [String] {
            let size = item.code.count
            if size > maxLength {
                return ["code is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class OvertimeAgreementRequiredChecksumRule: OvertimeAgreementRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: OvertimeAgreement) -> [String] {
            if item.checksum.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class OvertimeAgreementRequiredTitleRule: OvertimeAgreementRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: OvertimeAgreement) -> [String] {
            if item.title.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class OvertimeAgreementRateRangeRule: OvertimeAgreementRule {
        var min: Double
        var max: Double

        init(min: Double, max: Double) {
            self.min = min
            self.max = max
        }

        func check(_ item: OvertimeAgreement) -> [String] {
            let value = item.rate
            var problems: [String] = []
            if value < min {
                problems.append("rate \(value) is below \(min)")
            }
            if value > max {
                problems.append("rate \(value) is above \(max)")
            }
            return problems
        }
    }

    final class OvertimeAgreementRequiredCodeRule: OvertimeAgreementRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: OvertimeAgreement) -> [String] {
            if item.code.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class OvertimeAgreementCodePrefixRule: OvertimeAgreementRule {
        var prefix: String

        init(prefix: String) {
            self.prefix = prefix
        }

        func check(_ item: OvertimeAgreement) -> [String] {
            if !item.code.uppercased().hasPrefix(prefix.uppercased()) {
                return ["code must start with \(prefix)"]
            }
            return []
        }
    }

    /// Runs every rule of a overtime agreement.
    final class OvertimeAgreementValidator {
        var rules: [any OvertimeAgreementRule]

        init(rules: [any OvertimeAgreementRule]) {
            self.rules = rules
        }

        func validate(_ item: OvertimeAgreement) -> [String] {
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

        func requireValid(_ item: OvertimeAgreement) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.label()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [OvertimeAgreement]) -> [String: [String]] {
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

    static func defaultOvertimeAgreementValidator() -> OvertimeAgreementValidator {
        return OvertimeAgreementValidator(
            rules: [
                OvertimeAgreementCodeLengthRule(maxLength: 120),
                OvertimeAgreementRequiredChecksumRule(message: "overtime agreement needs a value"),
                OvertimeAgreementRequiredTitleRule(message: "overtime agreement needs a value"),
                OvertimeAgreementRateRangeRule(min: 3.0, max: 4355.2),
                OvertimeAgreementRequiredCodeRule(message: "overtime agreement needs an entry"),
                OvertimeAgreementCodePrefixRule(prefix: "ACM"),
            ]
        )
    }
}
