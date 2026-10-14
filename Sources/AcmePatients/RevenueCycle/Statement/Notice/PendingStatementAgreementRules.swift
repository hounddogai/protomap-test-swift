import AcmePlatform
import Foundation

extension RevenueCycle {
    /// A rule a pending statement agreement must pass. Check returns its problems, or none.
    protocol PendingStatementAgreementRule {
        func check(_ item: PendingStatementAgreement) -> [String]
    }

    final class PendingStatementAgreementCopayRangeRule: PendingStatementAgreementRule {
        var min: Double
        var max: Double

        init(min: Double, max: Double) {
            self.min = min
            self.max = max
        }

        func check(_ item: PendingStatementAgreement) -> [String] {
            let value = item.copay
            if value < min || value > max {
                return ["copay \(value) is outside \(min) to \(max)"]
            }
            return []
        }
    }

    final class PendingStatementAgreementRequiredNameRule: PendingStatementAgreementRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: PendingStatementAgreement) -> [String] {
            if item.name.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class PendingStatementAgreementCodePrefixRule: PendingStatementAgreementRule {
        var prefix: String

        init(prefix: String) {
            self.prefix = prefix
        }

        func check(_ item: PendingStatementAgreement) -> [String] {
            if !item.code.uppercased().hasPrefix(prefix.uppercased()) {
                return ["code must start with \(prefix)"]
            }
            return []
        }
    }

    final class PendingStatementAgreementAllowedUnitRule: PendingStatementAgreementRule {
        var allowed: [String]

        init(allowed: [String]) {
            self.allowed = allowed
        }

        func check(_ item: PendingStatementAgreement) -> [String] {
            if allowed.count == 0 {
                return []
            }
            if !allowed.contains(Kit.Text.normalize(item.unit)) {
                return ["unit \(item.unit) is too long"]
            }
            return []
        }
    }

    final class PendingStatementAgreementRequiredSpecialtyRule: PendingStatementAgreementRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: PendingStatementAgreement) -> [String] {
            if item.specialty.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    /// Runs every rule of a pending statement agreement.
    final class PendingStatementAgreementValidator {
        var rules: [any PendingStatementAgreementRule]

        init(rules: [any PendingStatementAgreementRule]) {
            self.rules = rules
        }

        func validate(_ item: PendingStatementAgreement) -> [String] {
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

        func requireValid(_ item: PendingStatementAgreement) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.label()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [PendingStatementAgreement]) -> [String: [String]] {
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

    static func defaultPendingStatementAgreementValidator() -> PendingStatementAgreementValidator {
        return PendingStatementAgreementValidator(
            rules: [
                PendingStatementAgreementCopayRangeRule(min: 2.5, max: 225.9),
                PendingStatementAgreementRequiredNameRule(message: "pending statement agreement needs this field"),
                PendingStatementAgreementCodePrefixRule(prefix: "OPS"),
                PendingStatementAgreementAllowedUnitRule(allowed: []),
                PendingStatementAgreementRequiredSpecialtyRule(message: "pending statement agreement needs an entry"),
            ]
        )
    }
}
