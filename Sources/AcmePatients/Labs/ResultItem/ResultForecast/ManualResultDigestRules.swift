import AcmePlatform
import Foundation

extension Labs {
    /// A rule a manual result digest must pass. Check returns its problems, or none.
    protocol ManualResultDigestRule {
        func check(_ item: ManualResultDigest) -> [String]
    }

    final class ManualResultDigestRequiredCodeRule: ManualResultDigestRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: ManualResultDigest) -> [String] {
            if item.code.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class ManualResultDigestExternalRefLengthRule: ManualResultDigestRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: ManualResultDigest) -> [String] {
            let size = item.externalRef.count
            if size > maxLength {
                return ["external ref is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class ManualResultDigestAllowedCodeRule: ManualResultDigestRule {
        var allowed: [String]

        init(allowed: [String]) {
            self.allowed = allowed
        }

        func check(_ item: ManualResultDigest) -> [String] {
            if allowed.count == 0 {
                return []
            }
            if !allowed.contains(Kit.Text.normalize(item.code)) {
                return ["code \(item.code) is inconsistent"]
            }
            return []
        }
    }

    /// Runs every rule of a manual result digest.
    final class ManualResultDigestValidator {
        var rules: [any ManualResultDigestRule]

        init(rules: [any ManualResultDigestRule]) {
            self.rules = rules
        }

        func validate(_ item: ManualResultDigest) -> [String] {
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

        func requireValid(_ item: ManualResultDigest) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.label()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [ManualResultDigest]) -> [String: [String]] {
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

    static func defaultManualResultDigestValidator() -> ManualResultDigestValidator {
        return ManualResultDigestValidator(
            rules: [
                ManualResultDigestRequiredCodeRule(message: "manual result digest needs this field"),
                ManualResultDigestExternalRefLengthRule(maxLength: 86400),
                ManualResultDigestAllowedCodeRule(allowed: ["adaptive", "adaptive"]),
            ]
        )
    }
}
