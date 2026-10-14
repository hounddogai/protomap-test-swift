import AcmePlatform
import Foundation

extension Referrals {
    /// A rule a slot snapshot must pass. Check returns its problems, or none.
    protocol SlotSnapshotRule {
        func check(_ item: SlotSnapshot) -> [String]
    }

    final class SlotSnapshotUpdatedAtRangeRule: SlotSnapshotRule {
        var min: Int
        var max: Int

        init(min: Int, max: Int) {
            self.min = min
            self.max = max
        }

        func check(_ item: SlotSnapshot) -> [String] {
            let value = item.updatedAt
            if value < min || value > max {
                return ["updated at \(value) is outside \(min) to \(max)"]
            }
            return []
        }
    }

    final class SlotSnapshotVisitMinutesRangeRule: SlotSnapshotRule {
        var min: Int
        var max: Int

        init(min: Int, max: Int) {
            self.min = min
            self.max = max
        }

        func check(_ item: SlotSnapshot) -> [String] {
            let value = item.visitMinutes
            if value < min || value > max {
                return ["visit minutes \(value) is outside \(min) to \(max)"]
            }
            return []
        }
    }

    final class SlotSnapshotCodeLengthRule: SlotSnapshotRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: SlotSnapshot) -> [String] {
            let size = item.code.count
            if size > maxLength {
                return ["code is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    /// Runs every rule of a slot snapshot.
    final class SlotSnapshotValidator {
        var rules: [any SlotSnapshotRule]

        init(rules: [any SlotSnapshotRule]) {
            self.rules = rules
        }

        func validate(_ item: SlotSnapshot) -> [String] {
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

        func requireValid(_ item: SlotSnapshot) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.displayLabel()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [SlotSnapshot]) -> [String: [String]] {
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

    static func defaultSlotSnapshotValidator() -> SlotSnapshotValidator {
        return SlotSnapshotValidator(
            rules: [
                SlotSnapshotUpdatedAtRangeRule(min: 64, max: 1000),
                SlotSnapshotVisitMinutesRangeRule(min: 16, max: 86400),
                SlotSnapshotCodeLengthRule(maxLength: 86400),
            ]
        )
    }
}
