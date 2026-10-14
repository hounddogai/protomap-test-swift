import AcmePlatform
import Foundation

extension Labs {
    /// A rule a legacy panel agreement must pass. Check returns its problems, or none.
    protocol LegacyPanelAgreementRule {
        func check(_ item: LegacyPanelAgreement) -> [String]
    }

    final class LegacyPanelAgreementAllowedNameRule: LegacyPanelAgreementRule {
        var allowed: [String]

        init(allowed: [String]) {
            self.allowed = allowed
        }

        func check(_ item: LegacyPanelAgreement) -> [String] {
            if allowed.count == 0 {
                return []
            }
            if !allowed.contains(Kit.Text.normalize(item.name)) {
                return ["name \(item.name) is missing"]
            }
            return []
        }
    }

    final class LegacyPanelAgreementUnitLengthRule: LegacyPanelAgreementRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: LegacyPanelAgreement) -> [String] {
            let size = item.unit.count
            if size > maxLength {
                return ["unit is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class LegacyPanelAgreementRequiredCodeRule: LegacyPanelAgreementRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: LegacyPanelAgreement) -> [String] {
            if item.code.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class LegacyPanelAgreementRequiredUnitRule: LegacyPanelAgreementRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: LegacyPanelAgreement) -> [String] {
            if item.unit.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    /// Runs every rule of a legacy panel agreement.
    final class LegacyPanelAgreementValidator {
        var rules: [any LegacyPanelAgreementRule]

        init(rules: [any LegacyPanelAgreementRule]) {
            self.rules = rules
        }

        func validate(_ item: LegacyPanelAgreement) -> [String] {
            var problems: [String] = []
            for rule in rules {
                for problem in rule.check(item) {
                    problems.append(problem)
                }
            }
            return problems
        }

        func requireValid(_ item: LegacyPanelAgreement) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.label()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [LegacyPanelAgreement]) -> [String: [String]] {
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

    static func defaultLegacyPanelAgreementValidator() -> LegacyPanelAgreementValidator {
        return LegacyPanelAgreementValidator(
            rules: [
                LegacyPanelAgreementAllowedNameRule(allowed: ["scheduled", "global"]),
                LegacyPanelAgreementUnitLengthRule(maxLength: 255),
                LegacyPanelAgreementRequiredCodeRule(message: "legacy panel agreement needs an entry"),
                LegacyPanelAgreementRequiredUnitRule(message: "legacy panel agreement needs this field"),
            ]
        )
    }
}
