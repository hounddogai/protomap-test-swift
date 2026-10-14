import AcmePlatform
import Foundation

extension RevenueCycle {
    /// A rule a authorization manifest must pass. Check returns its problems, or none.
    protocol AuthorizationManifestRule {
        func check(_ item: AuthorizationManifest) -> [String]
    }

    final class AuthorizationManifestClinicianIDLengthRule: AuthorizationManifestRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: AuthorizationManifest) -> [String] {
            let size = item.clinicianID.count
            if size > maxLength {
                return ["clinician id is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class AuthorizationManifestCodeLengthRule: AuthorizationManifestRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: AuthorizationManifest) -> [String] {
            let size = item.code.count
            if size > maxLength {
                return ["code is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class AuthorizationManifestCodePrefixRule: AuthorizationManifestRule {
        var prefix: String

        init(prefix: String) {
            self.prefix = prefix
        }

        func check(_ item: AuthorizationManifest) -> [String] {
            if !item.code.uppercased().hasPrefix(prefix.uppercased()) {
                return ["code must start with \(prefix)"]
            }
            return []
        }
    }

    /// Runs every rule of a authorization manifest.
    final class AuthorizationManifestValidator {
        var rules: [any AuthorizationManifestRule]

        init(rules: [any AuthorizationManifestRule]) {
            self.rules = rules
        }

        func validate(_ item: AuthorizationManifest) -> [String] {
            var problems: [String] = []
            for rule in rules {
                for problem in rule.check(item) {
                    problems.append(problem)
                }
            }
            return problems
        }

        func requireValid(_ item: AuthorizationManifest) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.displayLabel()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [AuthorizationManifest]) -> [String: [String]] {
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

    static func defaultAuthorizationManifestValidator() -> AuthorizationManifestValidator {
        return AuthorizationManifestValidator(
            rules: [
                AuthorizationManifestClinicianIDLengthRule(maxLength: 86400),
                AuthorizationManifestCodeLengthRule(maxLength: 3600),
                AuthorizationManifestCodePrefixRule(prefix: "REF"),
            ]
        )
    }
}
