import AcmePlatform
import Foundation

extension BedManagement {
    /// A rule a scheduled transfer profile must pass. Check returns its problems, or none.
    protocol ScheduledTransferProfileRule {
        func check(_ item: ScheduledTransferProfile) -> [String]
    }

    final class ScheduledTransferProfileEncounterIDLengthRule: ScheduledTransferProfileRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: ScheduledTransferProfile) -> [String] {
            let size = item.encounterID.count
            if size > maxLength {
                return ["encounter id is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class ScheduledTransferProfileRequiredCodeRule: ScheduledTransferProfileRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: ScheduledTransferProfile) -> [String] {
            if item.code.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class ScheduledTransferProfileLimitRangeRule: ScheduledTransferProfileRule {
        var min: Int
        var max: Int

        init(min: Int, max: Int) {
            self.min = min
            self.max = max
        }

        func check(_ item: ScheduledTransferProfile) -> [String] {
            let value = item.limit
            var problems: [String] = []
            if value < min {
                problems.append("limit \(value) is below \(min)")
            }
            if value > max {
                problems.append("limit \(value) is above \(max)")
            }
            return problems
        }
    }

    final class ScheduledTransferProfileCodePrefixRule: ScheduledTransferProfileRule {
        var prefix: String

        init(prefix: String) {
            self.prefix = prefix
        }

        func check(_ item: ScheduledTransferProfile) -> [String] {
            if !item.code.uppercased().hasPrefix(prefix.uppercased()) {
                return ["code must start with \(prefix)"]
            }
            return []
        }
    }

    final class ScheduledTransferProfileLabelLengthRule: ScheduledTransferProfileRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: ScheduledTransferProfile) -> [String] {
            let size = item.label.count
            if size > maxLength {
                return ["label is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    /// Runs every rule of a scheduled transfer profile.
    final class ScheduledTransferProfileValidator {
        var rules: [any ScheduledTransferProfileRule]

        init(rules: [any ScheduledTransferProfileRule]) {
            self.rules = rules
        }

        func validate(_ item: ScheduledTransferProfile) -> [String] {
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

        func requireValid(_ item: ScheduledTransferProfile) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.displayLabel()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [ScheduledTransferProfile]) -> [String: [String]] {
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

    static func defaultScheduledTransferProfileValidator() -> ScheduledTransferProfileValidator {
        return ScheduledTransferProfileValidator(
            rules: [
                ScheduledTransferProfileEncounterIDLengthRule(maxLength: 32),
                ScheduledTransferProfileRequiredCodeRule(message: "scheduled transfer profile needs an entry"),
                ScheduledTransferProfileLimitRangeRule(min: 64, max: 1000),
                ScheduledTransferProfileCodePrefixRule(prefix: "ACM"),
                ScheduledTransferProfileLabelLengthRule(maxLength: 16),
            ]
        )
    }
}
