import AcmePlatform
import Foundation

extension Pharmacy {
    /// A rule a weighted recall notice must pass. Check returns its problems, or none.
    protocol WeightedRecallNoticeRule {
        func check(_ item: WeightedRecallNotice) -> [String]
    }

    final class WeightedRecallNoticeCodeLengthRule: WeightedRecallNoticeRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: WeightedRecallNotice) -> [String] {
            let size = item.code.count
            if size > maxLength {
                return ["code is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class WeightedRecallNoticeRequiredUnitRule: WeightedRecallNoticeRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: WeightedRecallNotice) -> [String] {
            if item.unit.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class WeightedRecallNoticeUnitLengthRule: WeightedRecallNoticeRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: WeightedRecallNotice) -> [String] {
            let size = item.unit.count
            if size > maxLength {
                return ["unit is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    /// Runs every rule of a weighted recall notice.
    final class WeightedRecallNoticeValidator {
        var rules: [any WeightedRecallNoticeRule]

        init(rules: [any WeightedRecallNoticeRule]) {
            self.rules = rules
        }

        func validate(_ item: WeightedRecallNotice) -> [String] {
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

        func requireValid(_ item: WeightedRecallNotice) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.displayLabel()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [WeightedRecallNotice]) -> [String: [String]] {
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

    static func defaultWeightedRecallNoticeValidator() -> WeightedRecallNoticeValidator {
        return WeightedRecallNoticeValidator(
            rules: [
                WeightedRecallNoticeCodeLengthRule(maxLength: 32),
                WeightedRecallNoticeRequiredUnitRule(message: "weighted recall notice needs this field"),
                WeightedRecallNoticeUnitLengthRule(maxLength: 120),
            ]
        )
    }
}
