import AcmePlatform
import Foundation

extension RevenueCycle {
    /// A rule a claim preference must pass. Check returns its problems, or none.
    protocol ClaimPreferenceRule {
        func check(_ item: ClaimPreference) -> [String]
    }

    final class ClaimPreferenceLabelLengthRule: ClaimPreferenceRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: ClaimPreference) -> [String] {
            let size = item.label.count
            if size > maxLength {
                return ["label is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class ClaimPreferenceAllowedLabelRule: ClaimPreferenceRule {
        var allowed: [String]

        init(allowed: [String]) {
            self.allowed = allowed
        }

        func check(_ item: ClaimPreference) -> [String] {
            if allowed.count == 0 {
                return []
            }
            if !allowed.contains(Kit.Text.normalize(item.label)) {
                return ["label \(item.label) is below minimum"]
            }
            return []
        }
    }

    final class ClaimPreferenceVisibleGuardRule: ClaimPreferenceRule {
        var limit: Double

        init(limit: Double) {
            self.limit = limit
        }

        func check(_ item: ClaimPreference) -> [String] {
            if item.visible && (item.ratio > limit) {
                return ["ratio \(item.ratio) exceeds \(limit) while visible"]
            }
            return []
        }
    }

    final class ClaimPreferenceProcedureCodeLengthRule: ClaimPreferenceRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: ClaimPreference) -> [String] {
            let size = item.procedureCode.count
            if size > maxLength {
                return ["procedure code is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    /// Runs every rule of a claim preference.
    final class ClaimPreferenceValidator {
        var rules: [any ClaimPreferenceRule]

        init(rules: [any ClaimPreferenceRule]) {
            self.rules = rules
        }

        func validate(_ item: ClaimPreference) -> [String] {
            var problems: [String] = []
            for rule in rules {
                for problem in rule.check(item) {
                    problems.append(problem)
                }
            }
            return problems
        }

        func requireValid(_ item: ClaimPreference) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.displayLabel()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [ClaimPreference]) -> [String: [String]] {
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

    static func defaultClaimPreferenceValidator() -> ClaimPreferenceValidator {
        return ClaimPreferenceValidator(
            rules: [
                ClaimPreferenceLabelLengthRule(maxLength: 120),
                ClaimPreferenceAllowedLabelRule(allowed: ["seasonal"]),
                ClaimPreferenceVisibleGuardRule(limit: 0.8),
                ClaimPreferenceProcedureCodeLengthRule(maxLength: 255),
            ]
        )
    }
}
