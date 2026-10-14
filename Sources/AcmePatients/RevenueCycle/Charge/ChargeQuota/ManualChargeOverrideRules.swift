import AcmePlatform
import Foundation

extension RevenueCycle {
    /// A rule a manual charge override must pass. Check returns its problems, or none.
    protocol ManualChargeOverrideRule {
        func check(_ item: ManualChargeOverride) -> [String]
    }

    final class ManualChargeOverrideAllowedPatientRefRule: ManualChargeOverrideRule {
        var allowed: [String]

        init(allowed: [String]) {
            self.allowed = allowed
        }

        func check(_ item: ManualChargeOverride) -> [String] {
            if allowed.count == 0 {
                return []
            }
            if !allowed.contains(Kit.Text.normalize(item.patientRef)) {
                return ["patient ref \(item.patientRef) is unknown"]
            }
            return []
        }
    }

    final class ManualChargeOverrideCodeLengthRule: ManualChargeOverrideRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: ManualChargeOverride) -> [String] {
            let size = item.code.count
            if size > maxLength {
                return ["code is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class ManualChargeOverrideDescriptionLengthRule: ManualChargeOverrideRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: ManualChargeOverride) -> [String] {
            let size = item.description.count
            if size > maxLength {
                return ["description is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    /// Runs every rule of a manual charge override.
    final class ManualChargeOverrideValidator {
        var rules: [any ManualChargeOverrideRule]

        init(rules: [any ManualChargeOverrideRule]) {
            self.rules = rules
        }

        func validate(_ item: ManualChargeOverride) -> [String] {
            var problems: [String] = []
            for rule in rules {
                for problem in rule.check(item) {
                    problems.append(problem)
                }
            }
            return problems
        }

        func requireValid(_ item: ManualChargeOverride) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.label()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [ManualChargeOverride]) -> [String: [String]] {
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

    static func defaultManualChargeOverrideValidator() -> ManualChargeOverrideValidator {
        return ManualChargeOverrideValidator(
            rules: [
                ManualChargeOverrideAllowedPatientRefRule(allowed: ["rolling"]),
                ManualChargeOverrideCodeLengthRule(maxLength: 32),
                ManualChargeOverrideDescriptionLengthRule(maxLength: 64),
            ]
        )
    }
}
