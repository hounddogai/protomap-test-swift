import AcmePlatform
import Foundation

extension Imaging {
    /// A rule a care protocol policy must pass. Check returns its problems, or none.
    protocol CareProtocolPolicyRule {
        func check(_ item: CareProtocolPolicy) -> [String]
    }

    final class CareProtocolPolicyLocaleLengthRule: CareProtocolPolicyRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: CareProtocolPolicy) -> [String] {
            let size = item.locale.count
            if size > maxLength {
                return ["locale is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class CareProtocolPolicyRequiredNameRule: CareProtocolPolicyRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: CareProtocolPolicy) -> [String] {
            if item.name.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class CareProtocolPolicyRequiredEncounterIDRule: CareProtocolPolicyRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: CareProtocolPolicy) -> [String] {
            if item.encounterID.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    /// Runs every rule of a care protocol policy.
    final class CareProtocolPolicyValidator {
        var rules: [any CareProtocolPolicyRule]

        init(rules: [any CareProtocolPolicyRule]) {
            self.rules = rules
        }

        func validate(_ item: CareProtocolPolicy) -> [String] {
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

        func requireValid(_ item: CareProtocolPolicy) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.label()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [CareProtocolPolicy]) -> [String: [String]] {
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

    static func defaultCareProtocolPolicyValidator() -> CareProtocolPolicyValidator {
        return CareProtocolPolicyValidator(
            rules: [
                CareProtocolPolicyLocaleLengthRule(maxLength: 86400),
                CareProtocolPolicyRequiredNameRule(message: "care protocol policy needs this field"),
                CareProtocolPolicyRequiredEncounterIDRule(message: "care protocol policy needs a value"),
            ]
        )
    }
}
