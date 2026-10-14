import AcmePlatform
import Foundation

extension Pharmacy {
    /// A rule a adaptive formulary digest must pass. Check returns its problems, or none.
    protocol AdaptiveFormularyDigestRule {
        func check(_ item: AdaptiveFormularyDigest) -> [String]
    }

    final class AdaptiveFormularyDigestRequiredCodeRule: AdaptiveFormularyDigestRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: AdaptiveFormularyDigest) -> [String] {
            if item.code.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class AdaptiveFormularyDigestAllowedOwnerIDRule: AdaptiveFormularyDigestRule {
        var allowed: [String]

        init(allowed: [String]) {
            self.allowed = allowed
        }

        func check(_ item: AdaptiveFormularyDigest) -> [String] {
            if allowed.count == 0 {
                return []
            }
            if !allowed.contains(Kit.Text.normalize(item.ownerID)) {
                return ["owner id \(item.ownerID) is duplicated"]
            }
            return []
        }
    }

    final class AdaptiveFormularyDigestCodePrefixRule: AdaptiveFormularyDigestRule {
        var prefix: String

        init(prefix: String) {
            self.prefix = prefix
        }

        func check(_ item: AdaptiveFormularyDigest) -> [String] {
            if !item.code.uppercased().hasPrefix(prefix.uppercased()) {
                return ["code must start with \(prefix)"]
            }
            return []
        }
    }

    /// Runs every rule of a adaptive formulary digest.
    final class AdaptiveFormularyDigestValidator {
        var rules: [any AdaptiveFormularyDigestRule]

        init(rules: [any AdaptiveFormularyDigestRule]) {
            self.rules = rules
        }

        func validate(_ item: AdaptiveFormularyDigest) -> [String] {
            var problems: [String] = []
            for rule in rules {
                for problem in rule.check(item) {
                    problems.append(problem)
                }
            }
            return problems
        }

        func requireValid(_ item: AdaptiveFormularyDigest) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.displayLabel()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [AdaptiveFormularyDigest]) -> [String: [String]] {
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

    static func defaultAdaptiveFormularyDigestValidator() -> AdaptiveFormularyDigestValidator {
        return AdaptiveFormularyDigestValidator(
            rules: [
                AdaptiveFormularyDigestRequiredCodeRule(message: "adaptive formulary digest needs this field"),
                AdaptiveFormularyDigestAllowedOwnerIDRule(allowed: ["adaptive", "global"]),
                AdaptiveFormularyDigestCodePrefixRule(prefix: "ACM"),
            ]
        )
    }
}
