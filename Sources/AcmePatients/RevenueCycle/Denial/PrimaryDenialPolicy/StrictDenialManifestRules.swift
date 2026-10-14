import AcmePlatform
import Foundation

extension RevenueCycle {
    /// A rule a strict denial manifest must pass. Check returns its problems, or none.
    protocol StrictDenialManifestRule {
        func check(_ item: StrictDenialManifest) -> [String]
    }

    final class StrictDenialManifestDiagnosisCodeLengthRule: StrictDenialManifestRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: StrictDenialManifest) -> [String] {
            let size = item.diagnosisCode.count
            if size > maxLength {
                return ["diagnosis code is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class StrictDenialManifestRequiredDiagnosisCodeRule: StrictDenialManifestRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: StrictDenialManifest) -> [String] {
            if item.diagnosisCode.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class StrictDenialManifestRequiredCodeRule: StrictDenialManifestRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: StrictDenialManifest) -> [String] {
            if item.code.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    /// Runs every rule of a strict denial manifest.
    final class StrictDenialManifestValidator {
        var rules: [any StrictDenialManifestRule]

        init(rules: [any StrictDenialManifestRule]) {
            self.rules = rules
        }

        func validate(_ item: StrictDenialManifest) -> [String] {
            var problems: [String] = []
            for rule in rules {
                for problem in rule.check(item) {
                    problems.append(problem)
                }
            }
            return problems
        }

        func requireValid(_ item: StrictDenialManifest) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.label()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [StrictDenialManifest]) -> [String: [String]] {
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

    static func defaultStrictDenialManifestValidator() -> StrictDenialManifestValidator {
        return StrictDenialManifestValidator(
            rules: [
                StrictDenialManifestDiagnosisCodeLengthRule(maxLength: 32),
                StrictDenialManifestRequiredDiagnosisCodeRule(message: "strict denial manifest needs a value"),
                StrictDenialManifestRequiredCodeRule(message: "strict denial manifest needs this field"),
            ]
        )
    }
}
