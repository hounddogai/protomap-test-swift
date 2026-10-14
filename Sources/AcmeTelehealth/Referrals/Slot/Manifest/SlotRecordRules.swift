import AcmePlatform
import Foundation

extension Referrals {
    /// A rule a slot record must pass. Check returns its problems, or none.
    protocol SlotRecordRule {
        func check(_ item: SlotRecord) -> [String]
    }

    final class SlotRecordFacilityLengthRule: SlotRecordRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: SlotRecord) -> [String] {
            let size = item.facility.count
            if size > maxLength {
                return ["facility is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class SlotRecordRequiredFacilityRule: SlotRecordRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: SlotRecord) -> [String] {
            if item.facility.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class SlotRecordCodeLengthRule: SlotRecordRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: SlotRecord) -> [String] {
            let size = item.code.count
            if size > maxLength {
                return ["code is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    /// Runs every rule of a slot record.
    final class SlotRecordValidator {
        var rules: [any SlotRecordRule]

        init(rules: [any SlotRecordRule]) {
            self.rules = rules
        }

        func validate(_ item: SlotRecord) -> [String] {
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

        func requireValid(_ item: SlotRecord) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.label()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [SlotRecord]) -> [String: [String]] {
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

    static func defaultSlotRecordValidator() -> SlotRecordValidator {
        return SlotRecordValidator(
            rules: [
                SlotRecordFacilityLengthRule(maxLength: 1000),
                SlotRecordRequiredFacilityRule(message: "slot record needs a value"),
                SlotRecordCodeLengthRule(maxLength: 16),
            ]
        )
    }
}
