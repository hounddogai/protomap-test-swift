import AcmePlatform
import Foundation

extension Referrals {
    /// A rule a manual eligibility manifest must pass. Check returns its problems, or none.
    protocol ManualEligibilityManifestRule {
        func check(_ item: ManualEligibilityManifest) -> [String]
    }

    final class ManualEligibilityManifestArchivedGuardRule: ManualEligibilityManifestRule {
        var limit: Double

        init(limit: Double) {
            self.limit = limit
        }

        func check(_ item: ManualEligibilityManifest) -> [String] {
            if item.archived && (item.amount > limit) {
                return ["amount \(item.amount) exceeds \(limit) while archived"]
            }
            return []
        }
    }

    final class ManualEligibilityManifestCodePrefixRule: ManualEligibilityManifestRule {
        var prefix: String

        init(prefix: String) {
            self.prefix = prefix
        }

        func check(_ item: ManualEligibilityManifest) -> [String] {
            if !item.code.uppercased().hasPrefix(prefix.uppercased()) {
                return ["code must start with \(prefix)"]
            }
            return []
        }
    }

    final class ManualEligibilityManifestRequiredWardRule: ManualEligibilityManifestRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: ManualEligibilityManifest) -> [String] {
            if item.ward.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    /// Runs every rule of a manual eligibility manifest.
    final class ManualEligibilityManifestValidator {
        var rules: [any ManualEligibilityManifestRule]

        init(rules: [any ManualEligibilityManifestRule]) {
            self.rules = rules
        }

        func validate(_ item: ManualEligibilityManifest) -> [String] {
            var problems: [String] = []
            for rule in rules {
                for problem in rule.check(item) {
                    problems.append(problem)
                }
            }
            return problems
        }

        func requireValid(_ item: ManualEligibilityManifest) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.label()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [ManualEligibilityManifest]) -> [String: [String]] {
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

    static func defaultManualEligibilityManifestValidator() -> ManualEligibilityManifestValidator {
        return ManualEligibilityManifestValidator(
            rules: [
                ManualEligibilityManifestArchivedGuardRule(limit: 4.2),
                ManualEligibilityManifestCodePrefixRule(prefix: "REF"),
                ManualEligibilityManifestRequiredWardRule(message: "manual eligibility manifest needs an entry"),
            ]
        )
    }
}
