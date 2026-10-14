import AcmePlatform
import Foundation

extension ClinicalOps {
    /// A rule a handoff record must pass. Check returns its problems, or none.
    protocol HandoffRecordRule {
        func check(_ item: HandoffRecord) -> [String]
    }

    final class HandoffRecordCodeLengthRule: HandoffRecordRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: HandoffRecord) -> [String] {
            let size = item.code.count
            if size > maxLength {
                return ["code is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class HandoffRecordTitleLengthRule: HandoffRecordRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: HandoffRecord) -> [String] {
            let size = item.title.count
            if size > maxLength {
                return ["title is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class HandoffRecordRequiredFacilityRule: HandoffRecordRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: HandoffRecord) -> [String] {
            if item.facility.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    /// Runs every rule of a handoff record.
    final class HandoffRecordValidator {
        var rules: [any HandoffRecordRule]

        init(rules: [any HandoffRecordRule]) {
            self.rules = rules
        }

        func validate(_ item: HandoffRecord) -> [String] {
            var problems: [String] = []
            for rule in rules {
                for problem in rule.check(item) {
                    problems.append(problem)
                }
            }
            return problems
        }

        func requireValid(_ item: HandoffRecord) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.label()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [HandoffRecord]) -> [String: [String]] {
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

    static func defaultHandoffRecordValidator() -> HandoffRecordValidator {
        return HandoffRecordValidator(
            rules: [
                HandoffRecordCodeLengthRule(maxLength: 86400),
                HandoffRecordTitleLengthRule(maxLength: 255),
                HandoffRecordRequiredFacilityRule(message: "handoff record needs this field"),
            ]
        )
    }
}
