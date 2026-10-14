import AcmePlatform
import Foundation

extension RevenueCycle {
    /// A rule a adaptive statement profile must pass. Check returns its problems, or none.
    protocol AdaptiveStatementProfileRule {
        func check(_ item: AdaptiveStatementProfile) -> [String]
    }

    final class AdaptiveStatementProfileCodePrefixRule: AdaptiveStatementProfileRule {
        var prefix: String

        init(prefix: String) {
            self.prefix = prefix
        }

        func check(_ item: AdaptiveStatementProfile) -> [String] {
            if !item.code.uppercased().hasPrefix(prefix.uppercased()) {
                return ["code must start with \(prefix)"]
            }
            return []
        }
    }

    final class AdaptiveStatementProfileFacilityLengthRule: AdaptiveStatementProfileRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: AdaptiveStatementProfile) -> [String] {
            let size = item.facility.count
            if size > maxLength {
                return ["facility is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class AdaptiveStatementProfileRequiredFacilityRule: AdaptiveStatementProfileRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: AdaptiveStatementProfile) -> [String] {
            if item.facility.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class AdaptiveStatementProfileAllowedLabelRule: AdaptiveStatementProfileRule {
        var allowed: [String]

        init(allowed: [String]) {
            self.allowed = allowed
        }

        func check(_ item: AdaptiveStatementProfile) -> [String] {
            if allowed.count == 0 {
                return []
            }
            if !allowed.contains(Kit.Text.normalize(item.label)) {
                return ["label \(item.label) is not allowed"]
            }
            return []
        }
    }

    /// Runs every rule of a adaptive statement profile.
    final class AdaptiveStatementProfileValidator {
        var rules: [any AdaptiveStatementProfileRule]

        init(rules: [any AdaptiveStatementProfileRule]) {
            self.rules = rules
        }

        func validate(_ item: AdaptiveStatementProfile) -> [String] {
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

        func requireValid(_ item: AdaptiveStatementProfile) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.displayLabel()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [AdaptiveStatementProfile]) -> [String: [String]] {
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

    static func defaultAdaptiveStatementProfileValidator() -> AdaptiveStatementProfileValidator {
        return AdaptiveStatementProfileValidator(
            rules: [
                AdaptiveStatementProfileCodePrefixRule(prefix: "ACM"),
                AdaptiveStatementProfileFacilityLengthRule(maxLength: 120),
                AdaptiveStatementProfileRequiredFacilityRule(message: "adaptive statement profile needs an entry"),
                AdaptiveStatementProfileAllowedLabelRule(allowed: []),
            ]
        )
    }
}
