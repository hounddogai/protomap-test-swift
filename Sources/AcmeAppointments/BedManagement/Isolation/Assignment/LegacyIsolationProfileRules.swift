import AcmePlatform
import Foundation

extension BedManagement {
    /// A rule a legacy isolation profile must pass. Check returns its problems, or none.
    protocol LegacyIsolationProfileRule {
        func check(_ item: LegacyIsolationProfile) -> [String]
    }

    final class LegacyIsolationProfileCodeLengthRule: LegacyIsolationProfileRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: LegacyIsolationProfile) -> [String] {
            let size = item.code.count
            if size > maxLength {
                return ["code is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class LegacyIsolationProfileRequiredTitleRule: LegacyIsolationProfileRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: LegacyIsolationProfile) -> [String] {
            if item.title.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class LegacyIsolationProfileCodePrefixRule: LegacyIsolationProfileRule {
        var prefix: String

        init(prefix: String) {
            self.prefix = prefix
        }

        func check(_ item: LegacyIsolationProfile) -> [String] {
            if !item.code.uppercased().hasPrefix(prefix.uppercased()) {
                return ["code must start with \(prefix)"]
            }
            return []
        }
    }

    final class LegacyIsolationProfileFacilityLengthRule: LegacyIsolationProfileRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: LegacyIsolationProfile) -> [String] {
            let size = item.facility.count
            if size > maxLength {
                return ["facility is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class LegacyIsolationProfileAllowedCodeRule: LegacyIsolationProfileRule {
        var allowed: [String]

        init(allowed: [String]) {
            self.allowed = allowed
        }

        func check(_ item: LegacyIsolationProfile) -> [String] {
            if allowed.count == 0 {
                return []
            }
            if !allowed.contains(Kit.Text.normalize(item.code)) {
                return ["code \(item.code) is below minimum"]
            }
            return []
        }
    }

    /// Runs every rule of a legacy isolation profile.
    final class LegacyIsolationProfileValidator {
        var rules: [any LegacyIsolationProfileRule]

        init(rules: [any LegacyIsolationProfileRule]) {
            self.rules = rules
        }

        func validate(_ item: LegacyIsolationProfile) -> [String] {
            var problems: [String] = []
            for rule in rules {
                for problem in rule.check(item) {
                    problems.append(problem)
                }
            }
            return problems
        }

        func requireValid(_ item: LegacyIsolationProfile) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.label()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [LegacyIsolationProfile]) -> [String: [String]] {
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

    static func defaultLegacyIsolationProfileValidator() -> LegacyIsolationProfileValidator {
        return LegacyIsolationProfileValidator(
            rules: [
                LegacyIsolationProfileCodeLengthRule(maxLength: 255),
                LegacyIsolationProfileRequiredTitleRule(message: "legacy isolation profile needs an entry"),
                LegacyIsolationProfileCodePrefixRule(prefix: "ACM"),
                LegacyIsolationProfileFacilityLengthRule(maxLength: 86400),
                LegacyIsolationProfileAllowedCodeRule(allowed: ["weighted"]),
            ]
        )
    }
}
