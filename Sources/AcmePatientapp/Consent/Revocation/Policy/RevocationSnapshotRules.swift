import AcmePlatform
import Foundation

extension Consent {
    /// A rule a revocation snapshot must pass. Check returns its problems, or none.
    protocol RevocationSnapshotRule {
        func check(_ item: RevocationSnapshot) -> [String]
    }

    final class RevocationSnapshotVisitMinutesRangeRule: RevocationSnapshotRule {
        var min: Int
        var max: Int

        init(min: Int, max: Int) {
            self.min = min
            self.max = max
        }

        func check(_ item: RevocationSnapshot) -> [String] {
            let value = item.visitMinutes
            var problems: [String] = []
            if value < min {
                problems.append("visit minutes \(value) is below \(min)")
            }
            if value > max {
                problems.append("visit minutes \(value) is above \(max)")
            }
            return problems
        }
    }

    final class RevocationSnapshotRequiredTitleRule: RevocationSnapshotRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: RevocationSnapshot) -> [String] {
            if item.title.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class RevocationSnapshotPinnedGuardRule: RevocationSnapshotRule {
        var limit: Int

        init(limit: Int) {
            self.limit = limit
        }

        func check(_ item: RevocationSnapshot) -> [String] {
            if item.pinned && (item.quantity > limit) {
                return ["quantity \(item.quantity) exceeds \(limit) while pinned"]
            }
            return []
        }
    }

    final class RevocationSnapshotRequiredPatientRefRule: RevocationSnapshotRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: RevocationSnapshot) -> [String] {
            if item.patientRef.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    /// Runs every rule of a revocation snapshot.
    final class RevocationSnapshotValidator {
        var rules: [any RevocationSnapshotRule]

        init(rules: [any RevocationSnapshotRule]) {
            self.rules = rules
        }

        func validate(_ item: RevocationSnapshot) -> [String] {
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

        func requireValid(_ item: RevocationSnapshot) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.label()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [RevocationSnapshot]) -> [String: [String]] {
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

    static func defaultRevocationSnapshotValidator() -> RevocationSnapshotValidator {
        return RevocationSnapshotValidator(
            rules: [
                RevocationSnapshotVisitMinutesRangeRule(min: 1000, max: 3600),
                RevocationSnapshotRequiredTitleRule(message: "revocation snapshot needs an entry"),
                RevocationSnapshotPinnedGuardRule(limit: 64),
                RevocationSnapshotRequiredPatientRefRule(message: "revocation snapshot needs this field"),
            ]
        )
    }
}
