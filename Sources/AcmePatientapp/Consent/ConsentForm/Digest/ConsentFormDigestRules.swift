import AcmePlatform
import Foundation

extension Consent {
    /// A rule a consent form digest must pass. Check returns its problems, or none.
    protocol ConsentFormDigestRule {
        func check(_ item: ConsentFormDigest) -> [String]
    }

    final class ConsentFormDigestCodeLengthRule: ConsentFormDigestRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: ConsentFormDigest) -> [String] {
            let size = item.code.count
            if size > maxLength {
                return ["code is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class ConsentFormDigestRequiredCodeRule: ConsentFormDigestRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: ConsentFormDigest) -> [String] {
            if item.code.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class ConsentFormDigestCodePrefixRule: ConsentFormDigestRule {
        var prefix: String

        init(prefix: String) {
            self.prefix = prefix
        }

        func check(_ item: ConsentFormDigest) -> [String] {
            if !item.code.uppercased().hasPrefix(prefix.uppercased()) {
                return ["code must start with \(prefix)"]
            }
            return []
        }
    }

    /// Runs every rule of a consent form digest.
    final class ConsentFormDigestValidator {
        var rules: [any ConsentFormDigestRule]

        init(rules: [any ConsentFormDigestRule]) {
            self.rules = rules
        }

        func validate(_ item: ConsentFormDigest) -> [String] {
            var problems: [String] = []
            for rule in rules {
                for problem in rule.check(item) {
                    problems.append(problem)
                }
            }
            return problems
        }

        func requireValid(_ item: ConsentFormDigest) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.label()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [ConsentFormDigest]) -> [String: [String]] {
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

    static func defaultConsentFormDigestValidator() -> ConsentFormDigestValidator {
        return ConsentFormDigestValidator(
            rules: [
                ConsentFormDigestCodeLengthRule(maxLength: 32),
                ConsentFormDigestRequiredCodeRule(message: "consent form digest needs an entry"),
                ConsentFormDigestCodePrefixRule(prefix: "Q"),
            ]
        )
    }
}
