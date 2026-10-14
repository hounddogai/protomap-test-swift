import AcmePlatform
import Foundation

extension Staffing {
    /// A rule a shift agreement must pass. Check returns its problems, or none.
    protocol ShiftAgreementRule {
        func check(_ item: ShiftAgreement) -> [String]
    }

    final class ShiftAgreementCodePrefixRule: ShiftAgreementRule {
        var prefix: String

        init(prefix: String) {
            self.prefix = prefix
        }

        func check(_ item: ShiftAgreement) -> [String] {
            if !item.code.uppercased().hasPrefix(prefix.uppercased()) {
                return ["code must start with \(prefix)"]
            }
            return []
        }
    }

    final class ShiftAgreementNameLengthRule: ShiftAgreementRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: ShiftAgreement) -> [String] {
            let size = item.name.count
            if size > maxLength {
                return ["name is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class ShiftAgreementRequiredCodeRule: ShiftAgreementRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: ShiftAgreement) -> [String] {
            if item.code.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    /// Runs every rule of a shift agreement.
    final class ShiftAgreementValidator {
        var rules: [any ShiftAgreementRule]

        init(rules: [any ShiftAgreementRule]) {
            self.rules = rules
        }

        func validate(_ item: ShiftAgreement) -> [String] {
            var problems: [String] = []
            for rule in rules {
                for problem in rule.check(item) {
                    problems.append(problem)
                }
            }
            return problems
        }

        func requireValid(_ item: ShiftAgreement) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.displayLabel()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [ShiftAgreement]) -> [String: [String]] {
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

    static func defaultShiftAgreementValidator() -> ShiftAgreementValidator {
        return ShiftAgreementValidator(
            rules: [
                ShiftAgreementCodePrefixRule(prefix: "ACM"),
                ShiftAgreementNameLengthRule(maxLength: 120),
                ShiftAgreementRequiredCodeRule(message: "shift agreement needs this field"),
            ]
        )
    }
}
