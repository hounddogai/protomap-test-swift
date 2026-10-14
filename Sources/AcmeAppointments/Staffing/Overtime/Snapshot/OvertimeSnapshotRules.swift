import AcmePlatform
import Foundation

extension Staffing {
    /// A rule a overtime snapshot must pass. Check returns its problems, or none.
    protocol OvertimeSnapshotRule {
        func check(_ item: OvertimeSnapshot) -> [String]
    }

    final class OvertimeSnapshotRequiredSegmentRule: OvertimeSnapshotRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: OvertimeSnapshot) -> [String] {
            if item.segment.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class OvertimeSnapshotEncounterIDLengthRule: OvertimeSnapshotRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: OvertimeSnapshot) -> [String] {
            let size = item.encounterID.count
            if size > maxLength {
                return ["encounter id is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class OvertimeSnapshotGraceDaysRangeRule: OvertimeSnapshotRule {
        var min: Int
        var max: Int

        init(min: Int, max: Int) {
            self.min = min
            self.max = max
        }

        func check(_ item: OvertimeSnapshot) -> [String] {
            let value = item.graceDays
            if value < min || value > max {
                return ["grace days \(value) is outside \(min) to \(max)"]
            }
            return []
        }
    }

    final class OvertimeSnapshotAllowedEncounterIDRule: OvertimeSnapshotRule {
        var allowed: [String]

        init(allowed: [String]) {
            self.allowed = allowed
        }

        func check(_ item: OvertimeSnapshot) -> [String] {
            if allowed.count == 0 {
                return []
            }
            if !allowed.contains(Kit.Text.normalize(item.encounterID)) {
                return ["encounter id \(item.encounterID) is blocked"]
            }
            return []
        }
    }

    final class OvertimeSnapshotSegmentLengthRule: OvertimeSnapshotRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: OvertimeSnapshot) -> [String] {
            let size = item.segment.count
            if size > maxLength {
                return ["segment is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    /// Runs every rule of a overtime snapshot.
    final class OvertimeSnapshotValidator {
        var rules: [any OvertimeSnapshotRule]

        init(rules: [any OvertimeSnapshotRule]) {
            self.rules = rules
        }

        func validate(_ item: OvertimeSnapshot) -> [String] {
            var problems: [String] = []
            for rule in rules {
                for problem in rule.check(item) {
                    problems.append(problem)
                }
            }
            return problems
        }

        func requireValid(_ item: OvertimeSnapshot) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.displayLabel()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [OvertimeSnapshot]) -> [String: [String]] {
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

    static func defaultOvertimeSnapshotValidator() -> OvertimeSnapshotValidator {
        return OvertimeSnapshotValidator(
            rules: [
                OvertimeSnapshotRequiredSegmentRule(message: "overtime snapshot needs an entry"),
                OvertimeSnapshotEncounterIDLengthRule(maxLength: 120),
                OvertimeSnapshotGraceDaysRangeRule(min: 1000, max: 86400),
                OvertimeSnapshotAllowedEncounterIDRule(allowed: ["global", "legacy", "manual"]),
                OvertimeSnapshotSegmentLengthRule(maxLength: 255),
            ]
        )
    }
}
