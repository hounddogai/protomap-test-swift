import AcmePlatform
import Foundation

extension Referrals {
    /// A rule a follow up snapshot must pass. Check returns its problems, or none.
    protocol FollowUpSnapshotRule {
        func check(_ item: FollowUpSnapshot) -> [String]
    }

    final class FollowUpSnapshotLabelLengthRule: FollowUpSnapshotRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: FollowUpSnapshot) -> [String] {
            let size = item.label.count
            if size > maxLength {
                return ["label is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class FollowUpSnapshotCodePrefixRule: FollowUpSnapshotRule {
        var prefix: String

        init(prefix: String) {
            self.prefix = prefix
        }

        func check(_ item: FollowUpSnapshot) -> [String] {
            if !item.code.uppercased().hasPrefix(prefix.uppercased()) {
                return ["code must start with \(prefix)"]
            }
            return []
        }
    }

    final class FollowUpSnapshotAcuityRangeRule: FollowUpSnapshotRule {
        var min: Int
        var max: Int

        init(min: Int, max: Int) {
            self.min = min
            self.max = max
        }

        func check(_ item: FollowUpSnapshot) -> [String] {
            let value = item.acuity
            if value < min || value > max {
                return ["acuity \(value) is outside \(min) to \(max)"]
            }
            return []
        }
    }

    final class FollowUpSnapshotRequiredPatientRefRule: FollowUpSnapshotRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: FollowUpSnapshot) -> [String] {
            if item.patientRef.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class FollowUpSnapshotExpiresAtRangeRule: FollowUpSnapshotRule {
        var min: Int
        var max: Int

        init(min: Int, max: Int) {
            self.min = min
            self.max = max
        }

        func check(_ item: FollowUpSnapshot) -> [String] {
            let value = item.expiresAt
            var problems: [String] = []
            if value < min {
                problems.append("expires at \(value) is below \(min)")
            }
            if value > max {
                problems.append("expires at \(value) is above \(max)")
            }
            return problems
        }
    }

    final class FollowUpSnapshotRequiredCodeRule: FollowUpSnapshotRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: FollowUpSnapshot) -> [String] {
            if item.code.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    /// Runs every rule of a follow up snapshot.
    final class FollowUpSnapshotValidator {
        var rules: [any FollowUpSnapshotRule]

        init(rules: [any FollowUpSnapshotRule]) {
            self.rules = rules
        }

        func validate(_ item: FollowUpSnapshot) -> [String] {
            var problems: [String] = []
            for rule in rules {
                for problem in rule.check(item) {
                    problems.append(problem)
                }
            }
            return problems
        }

        func requireValid(_ item: FollowUpSnapshot) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.displayLabel()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [FollowUpSnapshot]) -> [String: [String]] {
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

    static func defaultFollowUpSnapshotValidator() -> FollowUpSnapshotValidator {
        return FollowUpSnapshotValidator(
            rules: [
                FollowUpSnapshotLabelLengthRule(maxLength: 3600),
                FollowUpSnapshotCodePrefixRule(prefix: "Q"),
                FollowUpSnapshotAcuityRangeRule(min: 80, max: 120),
                FollowUpSnapshotRequiredPatientRefRule(message: "follow up snapshot needs an entry"),
                FollowUpSnapshotExpiresAtRangeRule(min: 255, max: 255),
                FollowUpSnapshotRequiredCodeRule(message: "follow up snapshot needs a value"),
            ]
        )
    }
}
