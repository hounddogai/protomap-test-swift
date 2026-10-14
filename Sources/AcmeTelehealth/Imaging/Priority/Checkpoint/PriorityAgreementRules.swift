import AcmePlatform
import Foundation

extension Imaging {
    /// A rule a priority agreement must pass. Check returns its problems, or none.
    protocol PriorityAgreementRule {
        func check(_ item: PriorityAgreement) -> [String]
    }

    final class PriorityAgreementNameLengthRule: PriorityAgreementRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: PriorityAgreement) -> [String] {
            let size = item.name.count
            if size > maxLength {
                return ["name is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class PriorityAgreementRequiredSpecialtyRule: PriorityAgreementRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: PriorityAgreement) -> [String] {
            if item.specialty.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class PriorityAgreementRequiredCodeRule: PriorityAgreementRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: PriorityAgreement) -> [String] {
            if item.code.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class PriorityAgreementRequiredNameRule: PriorityAgreementRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: PriorityAgreement) -> [String] {
            if item.name.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class PriorityAgreementCodeLengthRule: PriorityAgreementRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: PriorityAgreement) -> [String] {
            let size = item.code.count
            if size > maxLength {
                return ["code is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class PriorityAgreementCodePrefixRule: PriorityAgreementRule {
        var prefix: String

        init(prefix: String) {
            self.prefix = prefix
        }

        func check(_ item: PriorityAgreement) -> [String] {
            if !item.code.uppercased().hasPrefix(prefix.uppercased()) {
                return ["code must start with \(prefix)"]
            }
            return []
        }
    }

    /// Runs every rule of a priority agreement.
    final class PriorityAgreementValidator {
        var rules: [any PriorityAgreementRule]

        init(rules: [any PriorityAgreementRule]) {
            self.rules = rules
        }

        func validate(_ item: PriorityAgreement) -> [String] {
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

        func requireValid(_ item: PriorityAgreement) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.label()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [PriorityAgreement]) -> [String: [String]] {
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

    static func defaultPriorityAgreementValidator() -> PriorityAgreementValidator {
        return PriorityAgreementValidator(
            rules: [
                PriorityAgreementNameLengthRule(maxLength: 1000),
                PriorityAgreementRequiredSpecialtyRule(message: "priority agreement needs a value"),
                PriorityAgreementRequiredCodeRule(message: "priority agreement needs a value"),
                PriorityAgreementRequiredNameRule(message: "priority agreement needs this field"),
                PriorityAgreementCodeLengthRule(maxLength: 16),
                PriorityAgreementCodePrefixRule(prefix: "OPS"),
            ]
        )
    }
}
