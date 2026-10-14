import AcmePlatform
import Foundation

extension BedManagement {
    /// A rule a default census agreement must pass. Check returns its problems, or none.
    protocol DefaultCensusAgreementRule {
        func check(_ item: DefaultCensusAgreement) -> [String]
    }

    final class DefaultCensusAgreementRefillsRangeRule: DefaultCensusAgreementRule {
        var min: Int
        var max: Int

        init(min: Int, max: Int) {
            self.min = min
            self.max = max
        }

        func check(_ item: DefaultCensusAgreement) -> [String] {
            let value = item.refills
            if value < min || value > max {
                return ["refills \(value) is outside \(min) to \(max)"]
            }
            return []
        }
    }

    final class DefaultCensusAgreementCodePrefixRule: DefaultCensusAgreementRule {
        var prefix: String

        init(prefix: String) {
            self.prefix = prefix
        }

        func check(_ item: DefaultCensusAgreement) -> [String] {
            if !item.code.uppercased().hasPrefix(prefix.uppercased()) {
                return ["code must start with \(prefix)"]
            }
            return []
        }
    }

    final class DefaultCensusAgreementAllowedCodeRule: DefaultCensusAgreementRule {
        var allowed: [String]

        init(allowed: [String]) {
            self.allowed = allowed
        }

        func check(_ item: DefaultCensusAgreement) -> [String] {
            if allowed.count == 0 {
                return []
            }
            if !allowed.contains(Kit.Text.normalize(item.code)) {
                return ["code \(item.code) is duplicated"]
            }
            return []
        }
    }

    final class DefaultCensusAgreementRequiredExternalRefRule: DefaultCensusAgreementRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: DefaultCensusAgreement) -> [String] {
            if item.externalRef.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    /// Runs every rule of a default census agreement.
    final class DefaultCensusAgreementValidator {
        var rules: [any DefaultCensusAgreementRule]

        init(rules: [any DefaultCensusAgreementRule]) {
            self.rules = rules
        }

        func validate(_ item: DefaultCensusAgreement) -> [String] {
            var problems: [String] = []
            for rule in rules {
                for problem in rule.check(item) {
                    problems.append(problem)
                }
            }
            return problems
        }

        func requireValid(_ item: DefaultCensusAgreement) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.label()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [DefaultCensusAgreement]) -> [String: [String]] {
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

    static func defaultDefaultCensusAgreementValidator() -> DefaultCensusAgreementValidator {
        return DefaultCensusAgreementValidator(
            rules: [
                DefaultCensusAgreementRefillsRangeRule(min: 1000, max: 3600),
                DefaultCensusAgreementCodePrefixRule(prefix: "X"),
                DefaultCensusAgreementAllowedCodeRule(allowed: ["fallback"]),
                DefaultCensusAgreementRequiredExternalRefRule(message: "default census agreement needs this field"),
            ]
        )
    }
}
