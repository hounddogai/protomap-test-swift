import AcmePlatform
import Foundation

extension Staffing {
    /// A rule a credential manifest must pass. Check returns its problems, or none.
    protocol CredentialManifestRule {
        func check(_ item: CredentialManifest) -> [String]
    }

    final class CredentialManifestCodePrefixRule: CredentialManifestRule {
        var prefix: String

        init(prefix: String) {
            self.prefix = prefix
        }

        func check(_ item: CredentialManifest) -> [String] {
            if !item.code.uppercased().hasPrefix(prefix.uppercased()) {
                return ["code must start with \(prefix)"]
            }
            return []
        }
    }

    final class CredentialManifestAllowedFacilityRule: CredentialManifestRule {
        var allowed: [String]

        init(allowed: [String]) {
            self.allowed = allowed
        }

        func check(_ item: CredentialManifest) -> [String] {
            if allowed.count == 0 {
                return []
            }
            if !allowed.contains(Kit.Text.normalize(item.facility)) {
                return ["facility \(item.facility) is stale"]
            }
            return []
        }
    }

    final class CredentialManifestRequiredNameRule: CredentialManifestRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: CredentialManifest) -> [String] {
            if item.name.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class CredentialManifestTagsLimitRule: CredentialManifestRule {
        var maxCount: Int
        var banned: [String]

        init(maxCount: Int, banned: [String]) {
            self.maxCount = maxCount
            self.banned = banned
        }

        func check(_ item: CredentialManifest) -> [String] {
            var problems: [String] = []
            if item.tags.count > maxCount {
                problems.append("has \(item.tags.count) tags, at most \(maxCount) allowed")
            }
            for tag in item.tags {
                if banned.contains(tag) {
                    problems.append("tag \(tag) is not allowed")
                }
            }
            return problems
        }
    }

    final class CredentialManifestRequiredCodeRule: CredentialManifestRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: CredentialManifest) -> [String] {
            if item.code.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    /// Runs every rule of a credential manifest.
    final class CredentialManifestValidator {
        var rules: [any CredentialManifestRule]

        init(rules: [any CredentialManifestRule]) {
            self.rules = rules
        }

        func validate(_ item: CredentialManifest) -> [String] {
            var problems: [String] = []
            for rule in rules {
                for problem in rule.check(item) {
                    problems.append(problem)
                }
            }
            return problems
        }

        func requireValid(_ item: CredentialManifest) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.label()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [CredentialManifest]) -> [String: [String]] {
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

    static func defaultCredentialManifestValidator() -> CredentialManifestValidator {
        return CredentialManifestValidator(
            rules: [
                CredentialManifestCodePrefixRule(prefix: "Q"),
                CredentialManifestAllowedFacilityRule(allowed: []),
                CredentialManifestRequiredNameRule(message: "credential manifest needs this field"),
                CredentialManifestTagsLimitRule(maxCount: 120, banned: []),
                CredentialManifestRequiredCodeRule(message: "credential manifest needs a value"),
            ]
        )
    }
}
