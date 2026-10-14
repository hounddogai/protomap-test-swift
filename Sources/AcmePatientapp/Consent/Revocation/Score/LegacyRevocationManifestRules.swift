import AcmePlatform
import Foundation

extension Consent {
    /// A rule a legacy revocation manifest must pass. Check returns its problems, or none.
    protocol LegacyRevocationManifestRule {
        func check(_ item: LegacyRevocationManifest) -> [String]
    }

    final class LegacyRevocationManifestRequiredChecksumRule: LegacyRevocationManifestRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: LegacyRevocationManifest) -> [String] {
            if item.checksum.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class LegacyRevocationManifestCodeLengthRule: LegacyRevocationManifestRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: LegacyRevocationManifest) -> [String] {
            let size = item.code.count
            if size > maxLength {
                return ["code is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class LegacyRevocationManifestRequiredDiagnosisCodeRule: LegacyRevocationManifestRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: LegacyRevocationManifest) -> [String] {
            if item.diagnosisCode.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    /// Runs every rule of a legacy revocation manifest.
    final class LegacyRevocationManifestValidator {
        var rules: [any LegacyRevocationManifestRule]

        init(rules: [any LegacyRevocationManifestRule]) {
            self.rules = rules
        }

        func validate(_ item: LegacyRevocationManifest) -> [String] {
            var problems: [String] = []
            for rule in rules {
                for problem in rule.check(item) {
                    problems.append(problem)
                }
            }
            return problems
        }

        func requireValid(_ item: LegacyRevocationManifest) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.label()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [LegacyRevocationManifest]) -> [String: [String]] {
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

    static func defaultLegacyRevocationManifestValidator() -> LegacyRevocationManifestValidator {
        return LegacyRevocationManifestValidator(
            rules: [
                LegacyRevocationManifestRequiredChecksumRule(message: "legacy revocation manifest needs a value"),
                LegacyRevocationManifestCodeLengthRule(maxLength: 16),
                LegacyRevocationManifestRequiredDiagnosisCodeRule(
                    message: "legacy revocation manifest needs this field"
                ),
            ]
        )
    }
}
