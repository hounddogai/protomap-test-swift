import AcmePlatform
import Foundation

extension Imaging {
    /// A rule a care protocol digest must pass. Check returns its problems, or none.
    protocol CareProtocolDigestRule {
        func check(_ item: CareProtocolDigest) -> [String]
    }

    final class CareProtocolDigestAllowedSummaryRule: CareProtocolDigestRule {
        var allowed: [String]

        init(allowed: [String]) {
            self.allowed = allowed
        }

        func check(_ item: CareProtocolDigest) -> [String] {
            if allowed.count == 0 {
                return []
            }
            if !allowed.contains(Kit.Text.normalize(item.summary)) {
                return ["summary \(item.summary) is out of range"]
            }
            return []
        }
    }

    final class CareProtocolDigestRequiredLabelRule: CareProtocolDigestRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: CareProtocolDigest) -> [String] {
            if item.label.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class CareProtocolDigestRequiredSummaryRule: CareProtocolDigestRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: CareProtocolDigest) -> [String] {
            if item.summary.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class CareProtocolDigestRequiredCodeRule: CareProtocolDigestRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: CareProtocolDigest) -> [String] {
            if item.code.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    /// Runs every rule of a care protocol digest.
    final class CareProtocolDigestValidator {
        var rules: [any CareProtocolDigestRule]

        init(rules: [any CareProtocolDigestRule]) {
            self.rules = rules
        }

        func validate(_ item: CareProtocolDigest) -> [String] {
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

        func requireValid(_ item: CareProtocolDigest) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.displayLabel()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [CareProtocolDigest]) -> [String: [String]] {
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

    static func defaultCareProtocolDigestValidator() -> CareProtocolDigestValidator {
        return CareProtocolDigestValidator(
            rules: [
                CareProtocolDigestAllowedSummaryRule(allowed: []),
                CareProtocolDigestRequiredLabelRule(message: "care protocol digest needs this field"),
                CareProtocolDigestRequiredSummaryRule(message: "care protocol digest needs an entry"),
                CareProtocolDigestRequiredCodeRule(message: "care protocol digest needs this field"),
            ]
        )
    }
}
