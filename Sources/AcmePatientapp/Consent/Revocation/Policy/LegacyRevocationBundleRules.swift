import AcmePlatform
import Foundation

extension Consent {
    /// A rule a legacy revocation bundle must pass. Check returns its problems, or none.
    protocol LegacyRevocationBundleRule {
        func check(_ item: LegacyRevocationBundle) -> [String]
    }

    final class LegacyRevocationBundleAllowedCodeRule: LegacyRevocationBundleRule {
        var allowed: [String]

        init(allowed: [String]) {
            self.allowed = allowed
        }

        func check(_ item: LegacyRevocationBundle) -> [String] {
            if allowed.count == 0 {
                return []
            }
            if !allowed.contains(Kit.Text.normalize(item.code)) {
                return ["code \(item.code) is too long"]
            }
            return []
        }
    }

    final class LegacyRevocationBundleRequiredBedRule: LegacyRevocationBundleRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: LegacyRevocationBundle) -> [String] {
            if item.bed.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class LegacyRevocationBundleOwnerIDLengthRule: LegacyRevocationBundleRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: LegacyRevocationBundle) -> [String] {
            let size = item.ownerID.count
            if size > maxLength {
                return ["owner id is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class LegacyRevocationBundleCodeLengthRule: LegacyRevocationBundleRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: LegacyRevocationBundle) -> [String] {
            let size = item.code.count
            if size > maxLength {
                return ["code is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    /// Runs every rule of a legacy revocation bundle.
    final class LegacyRevocationBundleValidator {
        var rules: [any LegacyRevocationBundleRule]

        init(rules: [any LegacyRevocationBundleRule]) {
            self.rules = rules
        }

        func validate(_ item: LegacyRevocationBundle) -> [String] {
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

        func requireValid(_ item: LegacyRevocationBundle) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.label()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [LegacyRevocationBundle]) -> [String: [String]] {
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

    static func defaultLegacyRevocationBundleValidator() -> LegacyRevocationBundleValidator {
        return LegacyRevocationBundleValidator(
            rules: [
                LegacyRevocationBundleAllowedCodeRule(allowed: []),
                LegacyRevocationBundleRequiredBedRule(message: "legacy revocation bundle needs an entry"),
                LegacyRevocationBundleOwnerIDLengthRule(maxLength: 80),
                LegacyRevocationBundleCodeLengthRule(maxLength: 120),
            ]
        )
    }
}
