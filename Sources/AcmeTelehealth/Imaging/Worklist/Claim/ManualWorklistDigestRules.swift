import AcmePlatform
import Foundation

extension Imaging {
    /// A rule a manual worklist digest must pass. Check returns its problems, or none.
    protocol ManualWorklistDigestRule {
        func check(_ item: ManualWorklistDigest) -> [String]
    }

    final class ManualWorklistDigestCodePrefixRule: ManualWorklistDigestRule {
        var prefix: String

        init(prefix: String) {
            self.prefix = prefix
        }

        func check(_ item: ManualWorklistDigest) -> [String] {
            if !item.code.uppercased().hasPrefix(prefix.uppercased()) {
                return ["code must start with \(prefix)"]
            }
            return []
        }
    }

    final class ManualWorklistDigestAllowedCodeRule: ManualWorklistDigestRule {
        var allowed: [String]

        init(allowed: [String]) {
            self.allowed = allowed
        }

        func check(_ item: ManualWorklistDigest) -> [String] {
            if allowed.count == 0 {
                return []
            }
            if !allowed.contains(Kit.Text.normalize(item.code)) {
                return ["code \(item.code) is stale"]
            }
            return []
        }
    }

    final class ManualWorklistDigestRequiredPhoneRule: ManualWorklistDigestRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: ManualWorklistDigest) -> [String] {
            if item.phone.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class ManualWorklistDigestRequiredTitleRule: ManualWorklistDigestRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: ManualWorklistDigest) -> [String] {
            if item.title.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    /// Runs every rule of a manual worklist digest.
    final class ManualWorklistDigestValidator {
        var rules: [any ManualWorklistDigestRule]

        init(rules: [any ManualWorklistDigestRule]) {
            self.rules = rules
        }

        func validate(_ item: ManualWorklistDigest) -> [String] {
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

        func requireValid(_ item: ManualWorklistDigest) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.label()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [ManualWorklistDigest]) -> [String: [String]] {
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

    static func defaultManualWorklistDigestValidator() -> ManualWorklistDigestValidator {
        return ManualWorklistDigestValidator(
            rules: [
                ManualWorklistDigestCodePrefixRule(prefix: "OPS"),
                ManualWorklistDigestAllowedCodeRule(allowed: []),
                ManualWorklistDigestRequiredPhoneRule(message: "manual worklist digest needs an entry"),
                ManualWorklistDigestRequiredTitleRule(message: "manual worklist digest needs this field"),
            ]
        )
    }
}
