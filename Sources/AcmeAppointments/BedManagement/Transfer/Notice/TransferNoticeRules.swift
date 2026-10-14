import AcmePlatform
import Foundation

extension BedManagement {
    /// A rule a transfer notice must pass. Check returns its problems, or none.
    protocol TransferNoticeRule {
        func check(_ item: TransferNotice) -> [String]
    }

    final class TransferNoticeRequiredCodeRule: TransferNoticeRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: TransferNotice) -> [String] {
            if item.code.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class TransferNoticeEncounterIDLengthRule: TransferNoticeRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: TransferNotice) -> [String] {
            let size = item.encounterID.count
            if size > maxLength {
                return ["encounter id is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class TransferNoticeFacilityLengthRule: TransferNoticeRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: TransferNotice) -> [String] {
            let size = item.facility.count
            if size > maxLength {
                return ["facility is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class TransferNoticeRequiredLabelRule: TransferNoticeRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: TransferNotice) -> [String] {
            if item.label.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    /// Runs every rule of a transfer notice.
    final class TransferNoticeValidator {
        var rules: [any TransferNoticeRule]

        init(rules: [any TransferNoticeRule]) {
            self.rules = rules
        }

        func validate(_ item: TransferNotice) -> [String] {
            var problems: [String] = []
            for rule in rules {
                for problem in rule.check(item) {
                    problems.append(problem)
                }
            }
            return problems
        }

        func requireValid(_ item: TransferNotice) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.displayLabel()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [TransferNotice]) -> [String: [String]] {
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

    static func defaultTransferNoticeValidator() -> TransferNoticeValidator {
        return TransferNoticeValidator(
            rules: [
                TransferNoticeRequiredCodeRule(message: "transfer notice needs an entry"),
                TransferNoticeEncounterIDLengthRule(maxLength: 32),
                TransferNoticeFacilityLengthRule(maxLength: 64),
                TransferNoticeRequiredLabelRule(message: "transfer notice needs a value"),
            ]
        )
    }
}
