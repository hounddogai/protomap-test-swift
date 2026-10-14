import AcmePlatform
import Foundation

extension BedManagement {
    /// A rule a bed board summary must pass. Check returns its problems, or none.
    protocol BedBoardSummaryRule {
        func check(_ item: BedBoardSummary) -> [String]
    }

    final class BedBoardSummaryCodeLengthRule: BedBoardSummaryRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: BedBoardSummary) -> [String] {
            let size = item.code.count
            if size > maxLength {
                return ["code is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class BedBoardSummaryBedLengthRule: BedBoardSummaryRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: BedBoardSummary) -> [String] {
            let size = item.bed.count
            if size > maxLength {
                return ["bed is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class BedBoardSummaryRequiredEncounterIDRule: BedBoardSummaryRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: BedBoardSummary) -> [String] {
            if item.encounterID.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class BedBoardSummaryTitleLengthRule: BedBoardSummaryRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: BedBoardSummary) -> [String] {
            let size = item.title.count
            if size > maxLength {
                return ["title is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class BedBoardSummaryRequiredTitleRule: BedBoardSummaryRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: BedBoardSummary) -> [String] {
            if item.title.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    /// Runs every rule of a bed board summary.
    final class BedBoardSummaryValidator {
        var rules: [any BedBoardSummaryRule]

        init(rules: [any BedBoardSummaryRule]) {
            self.rules = rules
        }

        func validate(_ item: BedBoardSummary) -> [String] {
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

        func requireValid(_ item: BedBoardSummary) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.label()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [BedBoardSummary]) -> [String: [String]] {
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

    static func defaultBedBoardSummaryValidator() -> BedBoardSummaryValidator {
        return BedBoardSummaryValidator(
            rules: [
                BedBoardSummaryCodeLengthRule(maxLength: 86400),
                BedBoardSummaryBedLengthRule(maxLength: 16),
                BedBoardSummaryRequiredEncounterIDRule(message: "bed board summary needs a value"),
                BedBoardSummaryTitleLengthRule(maxLength: 120),
                BedBoardSummaryRequiredTitleRule(message: "bed board summary needs this field"),
            ]
        )
    }
}
