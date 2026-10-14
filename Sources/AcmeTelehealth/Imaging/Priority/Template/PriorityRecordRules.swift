import AcmePlatform
import Foundation

extension Imaging {
    /// A rule a priority record must pass. Check returns its problems, or none.
    protocol PriorityRecordRule {
        func check(_ item: PriorityRecord) -> [String]
    }

    final class PriorityRecordVersionRangeRule: PriorityRecordRule {
        var min: Int
        var max: Int

        init(min: Int, max: Int) {
            self.min = min
            self.max = max
        }

        func check(_ item: PriorityRecord) -> [String] {
            let value = item.version
            var problems: [String] = []
            if value < min {
                problems.append("version \(value) is below \(min)")
            }
            if value > max {
                problems.append("version \(value) is above \(max)")
            }
            return problems
        }
    }

    final class PriorityRecordCopayRangeRule: PriorityRecordRule {
        var min: Double
        var max: Double

        init(min: Double, max: Double) {
            self.min = min
            self.max = max
        }

        func check(_ item: PriorityRecord) -> [String] {
            let value = item.copay
            if value < min || value > max {
                return ["copay \(value) is outside \(min) to \(max)"]
            }
            return []
        }
    }

    final class PriorityRecordReviewerLengthRule: PriorityRecordRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: PriorityRecord) -> [String] {
            let size = item.reviewer.count
            if size > maxLength {
                return ["reviewer is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class PriorityRecordCodeLengthRule: PriorityRecordRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: PriorityRecord) -> [String] {
            let size = item.code.count
            if size > maxLength {
                return ["code is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class PriorityRecordMinimumRangeRule: PriorityRecordRule {
        var min: Double
        var max: Double

        init(min: Double, max: Double) {
            self.min = min
            self.max = max
        }

        func check(_ item: PriorityRecord) -> [String] {
            let value = item.minimum
            var problems: [String] = []
            if value < min {
                problems.append("minimum \(value) is below \(min)")
            }
            if value > max {
                problems.append("minimum \(value) is above \(max)")
            }
            return problems
        }
    }

    final class PriorityRecordRequiredCodeRule: PriorityRecordRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: PriorityRecord) -> [String] {
            if item.code.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    /// Runs every rule of a priority record.
    final class PriorityRecordValidator {
        var rules: [any PriorityRecordRule]

        init(rules: [any PriorityRecordRule]) {
            self.rules = rules
        }

        func validate(_ item: PriorityRecord) -> [String] {
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

        func requireValid(_ item: PriorityRecord) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.label()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [PriorityRecord]) -> [String: [String]] {
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

    static func defaultPriorityRecordValidator() -> PriorityRecordValidator {
        return PriorityRecordValidator(
            rules: [
                PriorityRecordVersionRangeRule(min: 16, max: 255),
                PriorityRecordCopayRangeRule(min: 5.9, max: 3419.9),
                PriorityRecordReviewerLengthRule(maxLength: 16),
                PriorityRecordCodeLengthRule(maxLength: 1000),
                PriorityRecordMinimumRangeRule(min: 7.9, max: 4407.9),
                PriorityRecordRequiredCodeRule(message: "priority record needs an entry"),
            ]
        )
    }
}
