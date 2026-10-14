import AcmePlatform
import Foundation

extension BedManagement {
    /// A rule a bed board notice must pass. Check returns its problems, or none.
    protocol BedBoardNoticeRule {
        func check(_ item: BedBoardNotice) -> [String]
    }

    final class BedBoardNoticeRequiredTitleRule: BedBoardNoticeRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: BedBoardNotice) -> [String] {
            if item.title.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class BedBoardNoticeUpdatedAtRangeRule: BedBoardNoticeRule {
        var min: Int
        var max: Int

        init(min: Int, max: Int) {
            self.min = min
            self.max = max
        }

        func check(_ item: BedBoardNotice) -> [String] {
            let value = item.updatedAt
            var problems: [String] = []
            if value < min {
                problems.append("updated at \(value) is below \(min)")
            }
            if value > max {
                problems.append("updated at \(value) is above \(max)")
            }
            return problems
        }
    }

    final class BedBoardNoticeMinimumRangeRule: BedBoardNoticeRule {
        var min: Double
        var max: Double

        init(min: Double, max: Double) {
            self.min = min
            self.max = max
        }

        func check(_ item: BedBoardNotice) -> [String] {
            let value = item.minimum
            if value < min || value > max {
                return ["minimum \(value) is outside \(min) to \(max)"]
            }
            return []
        }
    }

    final class BedBoardNoticeApprovedGuardRule: BedBoardNoticeRule {
        var limit: Double

        init(limit: Double) {
            self.limit = limit
        }

        func check(_ item: BedBoardNotice) -> [String] {
            if item.approved && (item.minimum > limit) {
                return ["minimum \(item.minimum) exceeds \(limit) while approved"]
            }
            return []
        }
    }

    final class BedBoardNoticeEncounterIDLengthRule: BedBoardNoticeRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: BedBoardNotice) -> [String] {
            let size = item.encounterID.count
            if size > maxLength {
                return ["encounter id is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    /// Runs every rule of a bed board notice.
    final class BedBoardNoticeValidator {
        var rules: [any BedBoardNoticeRule]

        init(rules: [any BedBoardNoticeRule]) {
            self.rules = rules
        }

        func validate(_ item: BedBoardNotice) -> [String] {
            var problems: [String] = []
            for rule in rules {
                for problem in rule.check(item) {
                    problems.append(problem)
                }
            }
            return problems
        }

        func requireValid(_ item: BedBoardNotice) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.label()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [BedBoardNotice]) -> [String: [String]] {
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

    static func defaultBedBoardNoticeValidator() -> BedBoardNoticeValidator {
        return BedBoardNoticeValidator(
            rules: [
                BedBoardNoticeRequiredTitleRule(message: "bed board notice needs an entry"),
                BedBoardNoticeUpdatedAtRangeRule(min: 64, max: 120),
                BedBoardNoticeMinimumRangeRule(min: 0.8, max: 2603.7),
                BedBoardNoticeApprovedGuardRule(limit: 4.7),
                BedBoardNoticeEncounterIDLengthRule(maxLength: 255),
            ]
        )
    }
}
