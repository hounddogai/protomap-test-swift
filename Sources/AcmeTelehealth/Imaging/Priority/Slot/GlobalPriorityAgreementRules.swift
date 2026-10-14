import AcmePlatform
import Foundation

extension Imaging {
    /// A rule a global priority agreement must pass. Check returns its problems, or none.
    protocol GlobalPriorityAgreementRule {
        func check(_ item: GlobalPriorityAgreement) -> [String]
    }

    final class GlobalPriorityAgreementRequiredNameRule: GlobalPriorityAgreementRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: GlobalPriorityAgreement) -> [String] {
            if item.name.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class GlobalPriorityAgreementCodeLengthRule: GlobalPriorityAgreementRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: GlobalPriorityAgreement) -> [String] {
            let size = item.code.count
            if size > maxLength {
                return ["code is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class GlobalPriorityAgreementNameLengthRule: GlobalPriorityAgreementRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: GlobalPriorityAgreement) -> [String] {
            let size = item.name.count
            if size > maxLength {
                return ["name is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class GlobalPriorityAgreementOwnerIDLengthRule: GlobalPriorityAgreementRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: GlobalPriorityAgreement) -> [String] {
            let size = item.ownerID.count
            if size > maxLength {
                return ["owner id is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    /// Runs every rule of a global priority agreement.
    final class GlobalPriorityAgreementValidator {
        var rules: [any GlobalPriorityAgreementRule]

        init(rules: [any GlobalPriorityAgreementRule]) {
            self.rules = rules
        }

        func validate(_ item: GlobalPriorityAgreement) -> [String] {
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

        func requireValid(_ item: GlobalPriorityAgreement) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.label()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [GlobalPriorityAgreement]) -> [String: [String]] {
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

    static func defaultGlobalPriorityAgreementValidator() -> GlobalPriorityAgreementValidator {
        return GlobalPriorityAgreementValidator(
            rules: [
                GlobalPriorityAgreementRequiredNameRule(message: "global priority agreement needs this field"),
                GlobalPriorityAgreementCodeLengthRule(maxLength: 3600),
                GlobalPriorityAgreementNameLengthRule(maxLength: 80),
                GlobalPriorityAgreementOwnerIDLengthRule(maxLength: 32),
            ]
        )
    }
}
