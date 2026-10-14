import AcmePlatform
import Foundation

extension Consent {
    /// A rule a rolling revocation manifest must pass. Check returns its problems, or none.
    protocol RollingRevocationManifestRule {
        func check(_ item: RollingRevocationManifest) -> [String]
    }

    final class RollingRevocationManifestPayerLengthRule: RollingRevocationManifestRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: RollingRevocationManifest) -> [String] {
            let size = item.payer.count
            if size > maxLength {
                return ["payer is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class RollingRevocationManifestCodePrefixRule: RollingRevocationManifestRule {
        var prefix: String

        init(prefix: String) {
            self.prefix = prefix
        }

        func check(_ item: RollingRevocationManifest) -> [String] {
            if !item.code.uppercased().hasPrefix(prefix.uppercased()) {
                return ["code must start with \(prefix)"]
            }
            return []
        }
    }

    final class RollingRevocationManifestNameLengthRule: RollingRevocationManifestRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: RollingRevocationManifest) -> [String] {
            let size = item.name.count
            if size > maxLength {
                return ["name is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class RollingRevocationManifestCountryLengthRule: RollingRevocationManifestRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: RollingRevocationManifest) -> [String] {
            let size = item.country.count
            if size > maxLength {
                return ["country is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    /// Runs every rule of a rolling revocation manifest.
    final class RollingRevocationManifestValidator {
        var rules: [any RollingRevocationManifestRule]

        init(rules: [any RollingRevocationManifestRule]) {
            self.rules = rules
        }

        func validate(_ item: RollingRevocationManifest) -> [String] {
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

        func requireValid(_ item: RollingRevocationManifest) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.label()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [RollingRevocationManifest]) -> [String: [String]] {
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

    static func defaultRollingRevocationManifestValidator() -> RollingRevocationManifestValidator {
        return RollingRevocationManifestValidator(
            rules: [
                RollingRevocationManifestPayerLengthRule(maxLength: 86400),
                RollingRevocationManifestCodePrefixRule(prefix: "X"),
                RollingRevocationManifestNameLengthRule(maxLength: 16),
                RollingRevocationManifestCountryLengthRule(maxLength: 86400),
            ]
        )
    }
}
