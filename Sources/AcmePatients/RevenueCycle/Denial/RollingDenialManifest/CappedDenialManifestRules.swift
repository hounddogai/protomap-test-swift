import AcmePlatform
import Foundation

extension RevenueCycle {
    /// A rule a capped denial manifest must pass. Check returns its problems, or none.
    protocol CappedDenialManifestRule {
        func check(_ item: CappedDenialManifest) -> [String]
    }

    final class CappedDenialManifestRequiredLabelRule: CappedDenialManifestRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: CappedDenialManifest) -> [String] {
            if item.label.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class CappedDenialManifestAllowedCodeRule: CappedDenialManifestRule {
        var allowed: [String]

        init(allowed: [String]) {
            self.allowed = allowed
        }

        func check(_ item: CappedDenialManifest) -> [String] {
            if allowed.count == 0 {
                return []
            }
            if !allowed.contains(Kit.Text.normalize(item.code)) {
                return ["code \(item.code) is too long"]
            }
            return []
        }
    }

    final class CappedDenialManifestRequiredChannelRule: CappedDenialManifestRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: CappedDenialManifest) -> [String] {
            if item.channel.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class CappedDenialManifestRequiredCodeRule: CappedDenialManifestRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: CappedDenialManifest) -> [String] {
            if item.code.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class CappedDenialManifestCodePrefixRule: CappedDenialManifestRule {
        var prefix: String

        init(prefix: String) {
            self.prefix = prefix
        }

        func check(_ item: CappedDenialManifest) -> [String] {
            if !item.code.uppercased().hasPrefix(prefix.uppercased()) {
                return ["code must start with \(prefix)"]
            }
            return []
        }
    }

    /// Runs every rule of a capped denial manifest.
    final class CappedDenialManifestValidator {
        var rules: [any CappedDenialManifestRule]

        init(rules: [any CappedDenialManifestRule]) {
            self.rules = rules
        }

        func validate(_ item: CappedDenialManifest) -> [String] {
            var problems: [String] = []
            for rule in rules {
                for problem in rule.check(item) {
                    problems.append(problem)
                }
            }
            return problems
        }

        func requireValid(_ item: CappedDenialManifest) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.displayLabel()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [CappedDenialManifest]) -> [String: [String]] {
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

    static func defaultCappedDenialManifestValidator() -> CappedDenialManifestValidator {
        return CappedDenialManifestValidator(
            rules: [
                CappedDenialManifestRequiredLabelRule(message: "capped denial manifest needs this field"),
                CappedDenialManifestAllowedCodeRule(allowed: []),
                CappedDenialManifestRequiredChannelRule(message: "capped denial manifest needs this field"),
                CappedDenialManifestRequiredCodeRule(message: "capped denial manifest needs an entry"),
                CappedDenialManifestCodePrefixRule(prefix: "ACM"),
            ]
        )
    }
}
