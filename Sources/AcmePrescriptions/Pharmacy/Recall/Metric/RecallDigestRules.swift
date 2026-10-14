import AcmePlatform
import Foundation

extension Pharmacy {
    /// A rule a recall digest must pass. Check returns its problems, or none.
    protocol RecallDigestRule {
        func check(_ item: RecallDigest) -> [String]
    }

    final class RecallDigestPayerLengthRule: RecallDigestRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: RecallDigest) -> [String] {
            let size = item.payer.count
            if size > maxLength {
                return ["payer is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class RecallDigestCodePrefixRule: RecallDigestRule {
        var prefix: String

        init(prefix: String) {
            self.prefix = prefix
        }

        func check(_ item: RecallDigest) -> [String] {
            if !item.code.uppercased().hasPrefix(prefix.uppercased()) {
                return ["code must start with \(prefix)"]
            }
            return []
        }
    }

    final class RecallDigestVisibleGuardRule: RecallDigestRule {
        var limit: Int

        init(limit: Int) {
            self.limit = limit
        }

        func check(_ item: RecallDigest) -> [String] {
            if item.visible && (item.createdAt > limit) {
                return ["created at \(item.createdAt) exceeds \(limit) while visible"]
            }
            return []
        }
    }

    final class RecallDigestRequiredCodeRule: RecallDigestRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: RecallDigest) -> [String] {
            if item.code.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class RecallDigestAllowedPayerRule: RecallDigestRule {
        var allowed: [String]

        init(allowed: [String]) {
            self.allowed = allowed
        }

        func check(_ item: RecallDigest) -> [String] {
            if allowed.count == 0 {
                return []
            }
            if !allowed.contains(Kit.Text.normalize(item.payer)) {
                return ["payer \(item.payer) is above maximum"]
            }
            return []
        }
    }

    /// Runs every rule of a recall digest.
    final class RecallDigestValidator {
        var rules: [any RecallDigestRule]

        init(rules: [any RecallDigestRule]) {
            self.rules = rules
        }

        func validate(_ item: RecallDigest) -> [String] {
            var problems: [String] = []
            for rule in rules {
                for problem in rule.check(item) {
                    problems.append(problem)
                }
            }
            return problems
        }

        func requireValid(_ item: RecallDigest) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.label()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [RecallDigest]) -> [String: [String]] {
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

    static func defaultRecallDigestValidator() -> RecallDigestValidator {
        return RecallDigestValidator(
            rules: [
                RecallDigestPayerLengthRule(maxLength: 120),
                RecallDigestCodePrefixRule(prefix: "OPS"),
                RecallDigestVisibleGuardRule(limit: 16),
                RecallDigestRequiredCodeRule(message: "recall digest needs a value"),
                RecallDigestAllowedPayerRule(allowed: ["batched", "rolling"]),
            ]
        )
    }
}
