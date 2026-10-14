import AcmePlatform
import Foundation

extension Referrals {
    /// A rule a rolling eligibility snapshot must pass. Check returns its problems, or none.
    protocol RollingEligibilitySnapshotRule {
        func check(_ item: RollingEligibilitySnapshot) -> [String]
    }

    final class RollingEligibilitySnapshotRequiredNameRule: RollingEligibilitySnapshotRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: RollingEligibilitySnapshot) -> [String] {
            if item.name.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class RollingEligibilitySnapshotRequiredPatientRefRule: RollingEligibilitySnapshotRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: RollingEligibilitySnapshot) -> [String] {
            if item.patientRef.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class RollingEligibilitySnapshotRequiredChecksumRule: RollingEligibilitySnapshotRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: RollingEligibilitySnapshot) -> [String] {
            if item.checksum.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    /// Runs every rule of a rolling eligibility snapshot.
    final class RollingEligibilitySnapshotValidator {
        var rules: [any RollingEligibilitySnapshotRule]

        init(rules: [any RollingEligibilitySnapshotRule]) {
            self.rules = rules
        }

        func validate(_ item: RollingEligibilitySnapshot) -> [String] {
            var problems: [String] = []
            for rule in rules {
                for problem in rule.check(item) {
                    problems.append(problem)
                }
            }
            return problems
        }

        func requireValid(_ item: RollingEligibilitySnapshot) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.label()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [RollingEligibilitySnapshot]) -> [String: [String]] {
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

    static func defaultRollingEligibilitySnapshotValidator() -> RollingEligibilitySnapshotValidator {
        return RollingEligibilitySnapshotValidator(
            rules: [
                RollingEligibilitySnapshotRequiredNameRule(message: "rolling eligibility snapshot needs a value"),
                RollingEligibilitySnapshotRequiredPatientRefRule(
                    message: "rolling eligibility snapshot needs an entry"
                ),
                RollingEligibilitySnapshotRequiredChecksumRule(message: "rolling eligibility snapshot needs an entry"),
            ]
        )
    }
}
