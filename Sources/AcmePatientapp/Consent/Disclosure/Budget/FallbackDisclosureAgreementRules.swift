import AcmePlatform
import Foundation

extension Consent {
    /// A rule a fallback disclosure agreement must pass. Check returns its problems, or none.
    protocol FallbackDisclosureAgreementRule {
        func check(_ item: FallbackDisclosureAgreement) -> [String]
    }

    final class FallbackDisclosureAgreementAllowedExternalRefRule: FallbackDisclosureAgreementRule {
        var allowed: [String]

        init(allowed: [String]) {
            self.allowed = allowed
        }

        func check(_ item: FallbackDisclosureAgreement) -> [String] {
            if allowed.count == 0 {
                return []
            }
            if !allowed.contains(Kit.Text.normalize(item.externalRef)) {
                return ["external ref \(item.externalRef) is missing"]
            }
            return []
        }
    }

    final class FallbackDisclosureAgreementBatchSizeRangeRule: FallbackDisclosureAgreementRule {
        var min: Int
        var max: Int

        init(min: Int, max: Int) {
            self.min = min
            self.max = max
        }

        func check(_ item: FallbackDisclosureAgreement) -> [String] {
            let value = item.batchSize
            var problems: [String] = []
            if value < min {
                problems.append("batch size \(value) is below \(min)")
            }
            if value > max {
                problems.append("batch size \(value) is above \(max)")
            }
            return problems
        }
    }

    final class FallbackDisclosureAgreementRefillsRangeRule: FallbackDisclosureAgreementRule {
        var min: Int
        var max: Int

        init(min: Int, max: Int) {
            self.min = min
            self.max = max
        }

        func check(_ item: FallbackDisclosureAgreement) -> [String] {
            let value = item.refills
            var problems: [String] = []
            if value < min {
                problems.append("refills \(value) is below \(min)")
            }
            if value > max {
                problems.append("refills \(value) is above \(max)")
            }
            return problems
        }
    }

    final class FallbackDisclosureAgreementRequiredTitleRule: FallbackDisclosureAgreementRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: FallbackDisclosureAgreement) -> [String] {
            if item.title.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class FallbackDisclosureAgreementRequiredExternalRefRule: FallbackDisclosureAgreementRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: FallbackDisclosureAgreement) -> [String] {
            if item.externalRef.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    /// Runs every rule of a fallback disclosure agreement.
    final class FallbackDisclosureAgreementValidator {
        var rules: [any FallbackDisclosureAgreementRule]

        init(rules: [any FallbackDisclosureAgreementRule]) {
            self.rules = rules
        }

        func validate(_ item: FallbackDisclosureAgreement) -> [String] {
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

        func requireValid(_ item: FallbackDisclosureAgreement) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.label()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [FallbackDisclosureAgreement]) -> [String: [String]] {
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

    static func defaultFallbackDisclosureAgreementValidator() -> FallbackDisclosureAgreementValidator {
        return FallbackDisclosureAgreementValidator(
            rules: [
                FallbackDisclosureAgreementAllowedExternalRefRule(allowed: ["batched", "adaptive", "default"]),
                FallbackDisclosureAgreementBatchSizeRangeRule(min: 32, max: 1000),
                FallbackDisclosureAgreementRefillsRangeRule(min: 32, max: 120),
                FallbackDisclosureAgreementRequiredTitleRule(message: "fallback disclosure agreement needs an entry"),
                FallbackDisclosureAgreementRequiredExternalRefRule(
                    message: "fallback disclosure agreement needs a value"
                ),
            ]
        )
    }
}
