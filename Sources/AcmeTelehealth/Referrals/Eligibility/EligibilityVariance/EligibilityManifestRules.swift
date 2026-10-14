import AcmePlatform
import Foundation

extension Referrals {
    /// A rule a eligibility manifest must pass. Check returns its problems, or none.
    protocol EligibilityManifestRule {
        func check(_ item: EligibilityManifest) -> [String]
    }

    final class EligibilityManifestAllowedTitleRule: EligibilityManifestRule {
        var allowed: [String]

        init(allowed: [String]) {
            self.allowed = allowed
        }

        func check(_ item: EligibilityManifest) -> [String] {
            if allowed.count == 0 {
                return []
            }
            if !allowed.contains(Kit.Text.normalize(item.title)) {
                return ["title \(item.title) is missing"]
            }
            return []
        }
    }

    final class EligibilityManifestTitleLengthRule: EligibilityManifestRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: EligibilityManifest) -> [String] {
            let size = item.title.count
            if size > maxLength {
                return ["title is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class EligibilityManifestPhoneLengthRule: EligibilityManifestRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: EligibilityManifest) -> [String] {
            let size = item.phone.count
            if size > maxLength {
                return ["phone is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class EligibilityManifestRequiredTitleRule: EligibilityManifestRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: EligibilityManifest) -> [String] {
            if item.title.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class EligibilityManifestRequiredPhoneRule: EligibilityManifestRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: EligibilityManifest) -> [String] {
            if item.phone.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class EligibilityManifestProcedureCodeLengthRule: EligibilityManifestRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: EligibilityManifest) -> [String] {
            let size = item.procedureCode.count
            if size > maxLength {
                return ["procedure code is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    /// Runs every rule of a eligibility manifest.
    final class EligibilityManifestValidator {
        var rules: [any EligibilityManifestRule]

        init(rules: [any EligibilityManifestRule]) {
            self.rules = rules
        }

        func validate(_ item: EligibilityManifest) -> [String] {
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

        func requireValid(_ item: EligibilityManifest) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.label()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [EligibilityManifest]) -> [String: [String]] {
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

    static func defaultEligibilityManifestValidator() -> EligibilityManifestValidator {
        return EligibilityManifestValidator(
            rules: [
                EligibilityManifestAllowedTitleRule(allowed: []),
                EligibilityManifestTitleLengthRule(maxLength: 86400),
                EligibilityManifestPhoneLengthRule(maxLength: 64),
                EligibilityManifestRequiredTitleRule(message: "eligibility manifest needs a value"),
                EligibilityManifestRequiredPhoneRule(message: "eligibility manifest needs this field"),
                EligibilityManifestProcedureCodeLengthRule(maxLength: 255),
            ]
        )
    }
}
