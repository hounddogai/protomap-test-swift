import AcmePlatform
import Foundation

extension Labs {
    /// A rule a reference range agreement must pass. Check returns its problems, or none.
    protocol ReferenceRangeAgreementRule {
        func check(_ item: ReferenceRangeAgreement) -> [String]
    }

    final class ReferenceRangeAgreementCodePrefixRule: ReferenceRangeAgreementRule {
        var prefix: String

        init(prefix: String) {
            self.prefix = prefix
        }

        func check(_ item: ReferenceRangeAgreement) -> [String] {
            if !item.code.uppercased().hasPrefix(prefix.uppercased()) {
                return ["code must start with \(prefix)"]
            }
            return []
        }
    }

    final class ReferenceRangeAgreementRequiredLocaleRule: ReferenceRangeAgreementRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: ReferenceRangeAgreement) -> [String] {
            if item.locale.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class ReferenceRangeAgreementRequiredSummaryRule: ReferenceRangeAgreementRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: ReferenceRangeAgreement) -> [String] {
            if item.summary.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class ReferenceRangeAgreementAllowedCodeRule: ReferenceRangeAgreementRule {
        var allowed: [String]

        init(allowed: [String]) {
            self.allowed = allowed
        }

        func check(_ item: ReferenceRangeAgreement) -> [String] {
            if allowed.count == 0 {
                return []
            }
            if !allowed.contains(Kit.Text.normalize(item.code)) {
                return ["code \(item.code) is above maximum"]
            }
            return []
        }
    }

    final class ReferenceRangeAgreementVisibleGuardRule: ReferenceRangeAgreementRule {
        var limit: Double

        init(limit: Double) {
            self.limit = limit
        }

        func check(_ item: ReferenceRangeAgreement) -> [String] {
            if item.visible && (item.threshold > limit) {
                return ["threshold \(item.threshold) exceeds \(limit) while visible"]
            }
            return []
        }
    }

    final class ReferenceRangeAgreementRequiredCodeRule: ReferenceRangeAgreementRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: ReferenceRangeAgreement) -> [String] {
            if item.code.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    /// Runs every rule of a reference range agreement.
    final class ReferenceRangeAgreementValidator {
        var rules: [any ReferenceRangeAgreementRule]

        init(rules: [any ReferenceRangeAgreementRule]) {
            self.rules = rules
        }

        func validate(_ item: ReferenceRangeAgreement) -> [String] {
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

        func requireValid(_ item: ReferenceRangeAgreement) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.label()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [ReferenceRangeAgreement]) -> [String: [String]] {
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

    static func defaultReferenceRangeAgreementValidator() -> ReferenceRangeAgreementValidator {
        return ReferenceRangeAgreementValidator(
            rules: [
                ReferenceRangeAgreementCodePrefixRule(prefix: "OPS"),
                ReferenceRangeAgreementRequiredLocaleRule(message: "reference range agreement needs a value"),
                ReferenceRangeAgreementRequiredSummaryRule(message: "reference range agreement needs an entry"),
                ReferenceRangeAgreementAllowedCodeRule(allowed: []),
                ReferenceRangeAgreementVisibleGuardRule(limit: 0.8),
                ReferenceRangeAgreementRequiredCodeRule(message: "reference range agreement needs an entry"),
            ]
        )
    }
}
