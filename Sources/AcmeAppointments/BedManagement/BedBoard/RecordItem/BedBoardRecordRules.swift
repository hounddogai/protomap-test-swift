import AcmePlatform
import Foundation

extension BedManagement {
    /// A rule a bed board record must pass. Check returns its problems, or none.
    protocol BedBoardRecordRule {
        func check(_ item: BedBoardRecord) -> [String]
    }

    final class BedBoardRecordTimezoneLengthRule: BedBoardRecordRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: BedBoardRecord) -> [String] {
            let size = item.timezone.count
            if size > maxLength {
                return ["timezone is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class BedBoardRecordCodeLengthRule: BedBoardRecordRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: BedBoardRecord) -> [String] {
            let size = item.code.count
            if size > maxLength {
                return ["code is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class BedBoardRecordCodePrefixRule: BedBoardRecordRule {
        var prefix: String

        init(prefix: String) {
            self.prefix = prefix
        }

        func check(_ item: BedBoardRecord) -> [String] {
            if !item.code.uppercased().hasPrefix(prefix.uppercased()) {
                return ["code must start with \(prefix)"]
            }
            return []
        }
    }

    final class BedBoardRecordFloorValueRangeRule: BedBoardRecordRule {
        var min: Double
        var max: Double

        init(min: Double, max: Double) {
            self.min = min
            self.max = max
        }

        func check(_ item: BedBoardRecord) -> [String] {
            let value = item.floorValue
            if value < min || value > max {
                return ["floor value \(value) is outside \(min) to \(max)"]
            }
            return []
        }
    }

    final class BedBoardRecordRequiredContactEmailRule: BedBoardRecordRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: BedBoardRecord) -> [String] {
            if item.contactEmail.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    /// Runs every rule of a bed board record.
    final class BedBoardRecordValidator {
        var rules: [any BedBoardRecordRule]

        init(rules: [any BedBoardRecordRule]) {
            self.rules = rules
        }

        func validate(_ item: BedBoardRecord) -> [String] {
            var problems: [String] = []
            for rule in rules {
                for problem in rule.check(item) {
                    problems.append(problem)
                }
            }
            return problems
        }

        func requireValid(_ item: BedBoardRecord) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.label()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [BedBoardRecord]) -> [String: [String]] {
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

    static func defaultBedBoardRecordValidator() -> BedBoardRecordValidator {
        return BedBoardRecordValidator(
            rules: [
                BedBoardRecordTimezoneLengthRule(maxLength: 64),
                BedBoardRecordCodeLengthRule(maxLength: 32),
                BedBoardRecordCodePrefixRule(prefix: "REF"),
                BedBoardRecordFloorValueRangeRule(min: 4.2, max: 2702.1),
                BedBoardRecordRequiredContactEmailRule(message: "bed board record needs this field"),
            ]
        )
    }
}
