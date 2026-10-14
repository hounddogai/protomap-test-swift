import AcmePlatform
import Foundation

extension Consent {
    /// A rule a revocation manifest must pass. Check returns its problems, or none.
    protocol RevocationManifestRule {
        func check(_ item: RevocationManifest) -> [String]
    }

    final class RevocationManifestTitleLengthRule: RevocationManifestRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: RevocationManifest) -> [String] {
            let size = item.title.count
            if size > maxLength {
                return ["title is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class RevocationManifestRequiredPhoneRule: RevocationManifestRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: RevocationManifest) -> [String] {
            if item.phone.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class RevocationManifestRequiredTitleRule: RevocationManifestRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: RevocationManifest) -> [String] {
            if item.title.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class RevocationManifestCodePrefixRule: RevocationManifestRule {
        var prefix: String

        init(prefix: String) {
            self.prefix = prefix
        }

        func check(_ item: RevocationManifest) -> [String] {
            if !item.code.uppercased().hasPrefix(prefix.uppercased()) {
                return ["code must start with \(prefix)"]
            }
            return []
        }
    }

    /// Runs every rule of a revocation manifest.
    final class RevocationManifestValidator {
        var rules: [any RevocationManifestRule]

        init(rules: [any RevocationManifestRule]) {
            self.rules = rules
        }

        func validate(_ item: RevocationManifest) -> [String] {
            var problems: [String] = []
            for rule in rules {
                for problem in rule.check(item) {
                    problems.append(problem)
                }
            }
            return problems
        }

        func requireValid(_ item: RevocationManifest) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.label()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [RevocationManifest]) -> [String: [String]] {
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

    static func defaultRevocationManifestValidator() -> RevocationManifestValidator {
        return RevocationManifestValidator(
            rules: [
                RevocationManifestTitleLengthRule(maxLength: 255),
                RevocationManifestRequiredPhoneRule(message: "revocation manifest needs an entry"),
                RevocationManifestRequiredTitleRule(message: "revocation manifest needs a value"),
                RevocationManifestCodePrefixRule(prefix: "OPS"),
            ]
        )
    }
}
