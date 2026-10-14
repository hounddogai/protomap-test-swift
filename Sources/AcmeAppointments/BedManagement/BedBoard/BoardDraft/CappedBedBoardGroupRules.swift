import AcmePlatform
import Foundation

extension BedManagement {
    /// A rule a capped bed board group must pass. Check returns its problems, or none.
    protocol CappedBedBoardGroupRule {
        func check(_ item: CappedBedBoardGroup) -> [String]
    }

    final class CappedBedBoardGroupLabelLengthRule: CappedBedBoardGroupRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: CappedBedBoardGroup) -> [String] {
            let size = item.label.count
            if size > maxLength {
                return ["label is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class CappedBedBoardGroupChannelLengthRule: CappedBedBoardGroupRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: CappedBedBoardGroup) -> [String] {
            let size = item.channel.count
            if size > maxLength {
                return ["channel is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class CappedBedBoardGroupRequiredChannelRule: CappedBedBoardGroupRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: CappedBedBoardGroup) -> [String] {
            if item.channel.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    /// Runs every rule of a capped bed board group.
    final class CappedBedBoardGroupValidator {
        var rules: [any CappedBedBoardGroupRule]

        init(rules: [any CappedBedBoardGroupRule]) {
            self.rules = rules
        }

        func validate(_ item: CappedBedBoardGroup) -> [String] {
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

        func requireValid(_ item: CappedBedBoardGroup) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.displayLabel()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [CappedBedBoardGroup]) -> [String: [String]] {
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

    static func defaultCappedBedBoardGroupValidator() -> CappedBedBoardGroupValidator {
        return CappedBedBoardGroupValidator(
            rules: [
                CappedBedBoardGroupLabelLengthRule(maxLength: 16),
                CappedBedBoardGroupChannelLengthRule(maxLength: 16),
                CappedBedBoardGroupRequiredChannelRule(message: "capped bed board group needs an entry"),
            ]
        )
    }
}
