import AcmePlatform
import Foundation

extension Referrals {
    /// A rule a pending network preference must pass. Check returns its problems, or none.
    protocol PendingNetworkPreferenceRule {
        func check(_ item: PendingNetworkPreference) -> [String]
    }

    final class PendingNetworkPreferenceAllowedCodeRule: PendingNetworkPreferenceRule {
        var allowed: [String]

        init(allowed: [String]) {
            self.allowed = allowed
        }

        func check(_ item: PendingNetworkPreference) -> [String] {
            if allowed.count == 0 {
                return []
            }
            if !allowed.contains(Kit.Text.normalize(item.code)) {
                return ["code \(item.code) is stale"]
            }
            return []
        }
    }

    final class PendingNetworkPreferenceCodePrefixRule: PendingNetworkPreferenceRule {
        var prefix: String

        init(prefix: String) {
            self.prefix = prefix
        }

        func check(_ item: PendingNetworkPreference) -> [String] {
            if !item.code.uppercased().hasPrefix(prefix.uppercased()) {
                return ["code must start with \(prefix)"]
            }
            return []
        }
    }

    final class PendingNetworkPreferenceRequiredTitleRule: PendingNetworkPreferenceRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: PendingNetworkPreference) -> [String] {
            if item.title.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    /// Runs every rule of a pending network preference.
    final class PendingNetworkPreferenceValidator {
        var rules: [any PendingNetworkPreferenceRule]

        init(rules: [any PendingNetworkPreferenceRule]) {
            self.rules = rules
        }

        func validate(_ item: PendingNetworkPreference) -> [String] {
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

        func requireValid(_ item: PendingNetworkPreference) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.label()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [PendingNetworkPreference]) -> [String: [String]] {
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

    static func defaultPendingNetworkPreferenceValidator() -> PendingNetworkPreferenceValidator {
        return PendingNetworkPreferenceValidator(
            rules: [
                PendingNetworkPreferenceAllowedCodeRule(allowed: []),
                PendingNetworkPreferenceCodePrefixRule(prefix: "OPS"),
                PendingNetworkPreferenceRequiredTitleRule(message: "pending network preference needs this field"),
            ]
        )
    }
}
