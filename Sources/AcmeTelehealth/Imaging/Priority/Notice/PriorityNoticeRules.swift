import AcmePlatform
import Foundation

extension Imaging {
    /// A rule a priority notice must pass. Check returns its problems, or none.
    protocol PriorityNoticeRule {
        func check(_ item: PriorityNotice) -> [String]
    }

    final class PriorityNoticeTitleLengthRule: PriorityNoticeRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: PriorityNotice) -> [String] {
            let size = item.title.count
            if size > maxLength {
                return ["title is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class PriorityNoticeAcuityRangeRule: PriorityNoticeRule {
        var min: Int
        var max: Int

        init(min: Int, max: Int) {
            self.min = min
            self.max = max
        }

        func check(_ item: PriorityNotice) -> [String] {
            let value = item.acuity
            if value < min || value > max {
                return ["acuity \(value) is outside \(min) to \(max)"]
            }
            return []
        }
    }

    final class PriorityNoticeCodePrefixRule: PriorityNoticeRule {
        var prefix: String

        init(prefix: String) {
            self.prefix = prefix
        }

        func check(_ item: PriorityNotice) -> [String] {
            if !item.code.uppercased().hasPrefix(prefix.uppercased()) {
                return ["code must start with \(prefix)"]
            }
            return []
        }
    }

    final class PriorityNoticeSequenceRangeRule: PriorityNoticeRule {
        var min: Int
        var max: Int

        init(min: Int, max: Int) {
            self.min = min
            self.max = max
        }

        func check(_ item: PriorityNotice) -> [String] {
            let value = item.sequence
            var problems: [String] = []
            if value < min {
                problems.append("sequence \(value) is below \(min)")
            }
            if value > max {
                problems.append("sequence \(value) is above \(max)")
            }
            return problems
        }
    }

    /// Runs every rule of a priority notice.
    final class PriorityNoticeValidator {
        var rules: [any PriorityNoticeRule]

        init(rules: [any PriorityNoticeRule]) {
            self.rules = rules
        }

        func validate(_ item: PriorityNotice) -> [String] {
            var problems: [String] = []
            for rule in rules {
                for problem in rule.check(item) {
                    problems.append(problem)
                }
            }
            return problems
        }

        func requireValid(_ item: PriorityNotice) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.label()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [PriorityNotice]) -> [String: [String]] {
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

    static func defaultPriorityNoticeValidator() -> PriorityNoticeValidator {
        return PriorityNoticeValidator(
            rules: [
                PriorityNoticeTitleLengthRule(maxLength: 80),
                PriorityNoticeAcuityRangeRule(min: 64, max: 3600),
                PriorityNoticeCodePrefixRule(prefix: "X"),
                PriorityNoticeSequenceRangeRule(min: 16, max: 16),
            ]
        )
    }
}
