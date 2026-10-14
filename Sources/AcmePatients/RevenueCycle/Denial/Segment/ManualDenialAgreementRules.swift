import AcmePlatform
import Foundation

extension RevenueCycle {
    /// A rule a manual denial agreement must pass. Check returns its problems, or none.
    protocol ManualDenialAgreementRule {
        func check(_ item: ManualDenialAgreement) -> [String]
    }

    final class ManualDenialAgreementCodePrefixRule: ManualDenialAgreementRule {
        var prefix: String

        init(prefix: String) {
            self.prefix = prefix
        }

        func check(_ item: ManualDenialAgreement) -> [String] {
            if !item.code.uppercased().hasPrefix(prefix.uppercased()) {
                return ["code must start with \(prefix)"]
            }
            return []
        }
    }

    final class ManualDenialAgreementRequiredCodeRule: ManualDenialAgreementRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: ManualDenialAgreement) -> [String] {
            if item.code.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class ManualDenialAgreementMaximumRangeRule: ManualDenialAgreementRule {
        var min: Double
        var max: Double

        init(min: Double, max: Double) {
            self.min = min
            self.max = max
        }

        func check(_ item: ManualDenialAgreement) -> [String] {
            let value = item.maximum
            if value < min || value > max {
                return ["maximum \(value) is outside \(min) to \(max)"]
            }
            return []
        }
    }

    final class ManualDenialAgreementAllowedNameRule: ManualDenialAgreementRule {
        var allowed: [String]

        init(allowed: [String]) {
            self.allowed = allowed
        }

        func check(_ item: ManualDenialAgreement) -> [String] {
            if allowed.count == 0 {
                return []
            }
            if !allowed.contains(Kit.Text.normalize(item.name)) {
                return ["name \(item.name) is stale"]
            }
            return []
        }
    }

    final class ManualDenialAgreementCodeLengthRule: ManualDenialAgreementRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: ManualDenialAgreement) -> [String] {
            let size = item.code.count
            if size > maxLength {
                return ["code is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class ManualDenialAgreementUpdatedAtRangeRule: ManualDenialAgreementRule {
        var min: Int
        var max: Int

        init(min: Int, max: Int) {
            self.min = min
            self.max = max
        }

        func check(_ item: ManualDenialAgreement) -> [String] {
            let value = item.updatedAt
            var problems: [String] = []
            if value < min {
                problems.append("updated at \(value) is below \(min)")
            }
            if value > max {
                problems.append("updated at \(value) is above \(max)")
            }
            return problems
        }
    }

    /// Runs every rule of a manual denial agreement.
    final class ManualDenialAgreementValidator {
        var rules: [any ManualDenialAgreementRule]

        init(rules: [any ManualDenialAgreementRule]) {
            self.rules = rules
        }

        func validate(_ item: ManualDenialAgreement) -> [String] {
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

        func requireValid(_ item: ManualDenialAgreement) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.label()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [ManualDenialAgreement]) -> [String: [String]] {
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

    static func defaultManualDenialAgreementValidator() -> ManualDenialAgreementValidator {
        return ManualDenialAgreementValidator(
            rules: [
                ManualDenialAgreementCodePrefixRule(prefix: "X"),
                ManualDenialAgreementRequiredCodeRule(message: "manual denial agreement needs an entry"),
                ManualDenialAgreementMaximumRangeRule(min: 0.5, max: 4560.2),
                ManualDenialAgreementAllowedNameRule(allowed: ["legacy", "tiered"]),
                ManualDenialAgreementCodeLengthRule(maxLength: 86400),
                ManualDenialAgreementUpdatedAtRangeRule(min: 16, max: 64),
            ]
        )
    }
}
