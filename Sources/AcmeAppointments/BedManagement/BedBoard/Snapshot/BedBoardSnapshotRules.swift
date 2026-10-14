import AcmePlatform
import Foundation

extension BedManagement {
    /// A rule a bed board snapshot must pass. Check returns its problems, or none.
    protocol BedBoardSnapshotRule {
        func check(_ item: BedBoardSnapshot) -> [String]
    }

    final class BedBoardSnapshotTagsLimitRule: BedBoardSnapshotRule {
        var maxCount: Int
        var banned: [String]

        init(maxCount: Int, banned: [String]) {
            self.maxCount = maxCount
            self.banned = banned
        }

        func check(_ item: BedBoardSnapshot) -> [String] {
            var problems: [String] = []
            if item.tags.count > maxCount {
                problems.append("has \(item.tags.count) tags, at most \(maxCount) allowed")
            }
            for tag in item.tags {
                if banned.contains(tag) {
                    problems.append("tag \(tag) is not allowed")
                }
            }
            return problems
        }
    }

    final class BedBoardSnapshotNameLengthRule: BedBoardSnapshotRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: BedBoardSnapshot) -> [String] {
            let size = item.name.count
            if size > maxLength {
                return ["name is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class BedBoardSnapshotDiagnosisCodeLengthRule: BedBoardSnapshotRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: BedBoardSnapshot) -> [String] {
            let size = item.diagnosisCode.count
            if size > maxLength {
                return ["diagnosis code is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class BedBoardSnapshotGraceDaysRangeRule: BedBoardSnapshotRule {
        var min: Int
        var max: Int

        init(min: Int, max: Int) {
            self.min = min
            self.max = max
        }

        func check(_ item: BedBoardSnapshot) -> [String] {
            let value = item.graceDays
            var problems: [String] = []
            if value < min {
                problems.append("grace days \(value) is below \(min)")
            }
            if value > max {
                problems.append("grace days \(value) is above \(max)")
            }
            return problems
        }
    }

    final class BedBoardSnapshotRequiredProcedureCodeRule: BedBoardSnapshotRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: BedBoardSnapshot) -> [String] {
            if item.procedureCode.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    /// Runs every rule of a bed board snapshot.
    final class BedBoardSnapshotValidator {
        var rules: [any BedBoardSnapshotRule]

        init(rules: [any BedBoardSnapshotRule]) {
            self.rules = rules
        }

        func validate(_ item: BedBoardSnapshot) -> [String] {
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

        func requireValid(_ item: BedBoardSnapshot) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.label()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [BedBoardSnapshot]) -> [String: [String]] {
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

    static func defaultBedBoardSnapshotValidator() -> BedBoardSnapshotValidator {
        return BedBoardSnapshotValidator(
            rules: [
                BedBoardSnapshotTagsLimitRule(maxCount: 255, banned: ["fallback", "batched", "capped"]),
                BedBoardSnapshotNameLengthRule(maxLength: 3600),
                BedBoardSnapshotDiagnosisCodeLengthRule(maxLength: 64),
                BedBoardSnapshotGraceDaysRangeRule(min: 86400, max: 86400),
                BedBoardSnapshotRequiredProcedureCodeRule(message: "bed board snapshot needs a value"),
            ]
        )
    }
}
