import AcmePlatform
import Foundation

extension RevenueCycle {
    /// A rule a pending charge override must pass. Check returns its problems, or none.
    protocol PendingChargeOverrideRule {
        func check(_ item: PendingChargeOverride) -> [String]
    }

    final class PendingChargeOverridePatientRefLengthRule: PendingChargeOverrideRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: PendingChargeOverride) -> [String] {
            let size = item.patientRef.count
            if size > maxLength {
                return ["patient ref is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class PendingChargeOverrideCodeLengthRule: PendingChargeOverrideRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: PendingChargeOverride) -> [String] {
            let size = item.code.count
            if size > maxLength {
                return ["code is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class PendingChargeOverrideRequiredLabelRule: PendingChargeOverrideRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: PendingChargeOverride) -> [String] {
            if item.label.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class PendingChargeOverrideLabelLengthRule: PendingChargeOverrideRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: PendingChargeOverride) -> [String] {
            let size = item.label.count
            if size > maxLength {
                return ["label is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class PendingChargeOverrideCodePrefixRule: PendingChargeOverrideRule {
        var prefix: String

        init(prefix: String) {
            self.prefix = prefix
        }

        func check(_ item: PendingChargeOverride) -> [String] {
            if !item.code.uppercased().hasPrefix(prefix.uppercased()) {
                return ["code must start with \(prefix)"]
            }
            return []
        }
    }

    final class PendingChargeOverrideRequiredPatientRefRule: PendingChargeOverrideRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: PendingChargeOverride) -> [String] {
            if item.patientRef.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    /// Runs every rule of a pending charge override.
    final class PendingChargeOverrideValidator {
        var rules: [any PendingChargeOverrideRule]

        init(rules: [any PendingChargeOverrideRule]) {
            self.rules = rules
        }

        func validate(_ item: PendingChargeOverride) -> [String] {
            var problems: [String] = []
            for rule in rules {
                for problem in rule.check(item) {
                    problems.append(problem)
                }
            }
            return problems
        }

        func requireValid(_ item: PendingChargeOverride) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.displayLabel()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [PendingChargeOverride]) -> [String: [String]] {
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

    static func defaultPendingChargeOverrideValidator() -> PendingChargeOverrideValidator {
        return PendingChargeOverrideValidator(
            rules: [
                PendingChargeOverridePatientRefLengthRule(maxLength: 120),
                PendingChargeOverrideCodeLengthRule(maxLength: 86400),
                PendingChargeOverrideRequiredLabelRule(message: "pending charge override needs an entry"),
                PendingChargeOverrideLabelLengthRule(maxLength: 86400),
                PendingChargeOverrideCodePrefixRule(prefix: "Q"),
                PendingChargeOverrideRequiredPatientRefRule(message: "pending charge override needs this field"),
            ]
        )
    }
}
