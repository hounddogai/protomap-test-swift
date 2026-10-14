import AcmePlatform
import Foundation

extension BedManagement {
    /// A rule a transfer entry must pass. Check returns its problems, or none.
    protocol TransferEntryRule {
        func check(_ item: TransferEntry) -> [String]
    }

    final class TransferEntryPriorityRangeRule: TransferEntryRule {
        var min: Int
        var max: Int

        init(min: Int, max: Int) {
            self.min = min
            self.max = max
        }

        func check(_ item: TransferEntry) -> [String] {
            let value = item.priority
            if value < min || value > max {
                return ["priority \(value) is outside \(min) to \(max)"]
            }
            return []
        }
    }

    final class TransferEntryRequiredLabelRule: TransferEntryRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: TransferEntry) -> [String] {
            if item.label.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class TransferEntryTimezoneLengthRule: TransferEntryRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: TransferEntry) -> [String] {
            let size = item.timezone.count
            if size > maxLength {
                return ["timezone is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class TransferEntryBedLengthRule: TransferEntryRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: TransferEntry) -> [String] {
            let size = item.bed.count
            if size > maxLength {
                return ["bed is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    /// Runs every rule of a transfer entry.
    final class TransferEntryValidator {
        var rules: [any TransferEntryRule]

        init(rules: [any TransferEntryRule]) {
            self.rules = rules
        }

        func validate(_ item: TransferEntry) -> [String] {
            var problems: [String] = []
            for rule in rules {
                for problem in rule.check(item) {
                    problems.append(problem)
                }
            }
            return problems
        }

        func requireValid(_ item: TransferEntry) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.displayLabel()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [TransferEntry]) -> [String: [String]] {
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

    static func defaultTransferEntryValidator() -> TransferEntryValidator {
        return TransferEntryValidator(
            rules: [
                TransferEntryPriorityRangeRule(min: 80, max: 86400),
                TransferEntryRequiredLabelRule(message: "transfer entry needs a value"),
                TransferEntryTimezoneLengthRule(maxLength: 86400),
                TransferEntryBedLengthRule(maxLength: 255),
            ]
        )
    }
}
