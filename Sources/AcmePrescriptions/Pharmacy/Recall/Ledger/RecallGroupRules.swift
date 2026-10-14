import AcmePlatform
import Foundation

extension Pharmacy {
    /// A rule a recall group must pass. Check returns its problems, or none.
    protocol RecallGroupRule {
        func check(_ item: RecallGroup) -> [String]
    }

    final class RecallGroupNameLengthRule: RecallGroupRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: RecallGroup) -> [String] {
            let size = item.name.count
            if size > maxLength {
                return ["name is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class RecallGroupTimezoneLengthRule: RecallGroupRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: RecallGroup) -> [String] {
            let size = item.timezone.count
            if size > maxLength {
                return ["timezone is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class RecallGroupVisitMinutesRangeRule: RecallGroupRule {
        var min: Int
        var max: Int

        init(min: Int, max: Int) {
            self.min = min
            self.max = max
        }

        func check(_ item: RecallGroup) -> [String] {
            let value = item.visitMinutes
            var problems: [String] = []
            if value < min {
                problems.append("visit minutes \(value) is below \(min)")
            }
            if value > max {
                problems.append("visit minutes \(value) is above \(max)")
            }
            return problems
        }
    }

    final class RecallGroupCodePrefixRule: RecallGroupRule {
        var prefix: String

        init(prefix: String) {
            self.prefix = prefix
        }

        func check(_ item: RecallGroup) -> [String] {
            if !item.code.uppercased().hasPrefix(prefix.uppercased()) {
                return ["code must start with \(prefix)"]
            }
            return []
        }
    }

    final class RecallGroupRequiredCodeRule: RecallGroupRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: RecallGroup) -> [String] {
            if item.code.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    /// Runs every rule of a recall group.
    final class RecallGroupValidator {
        var rules: [any RecallGroupRule]

        init(rules: [any RecallGroupRule]) {
            self.rules = rules
        }

        func validate(_ item: RecallGroup) -> [String] {
            var problems: [String] = []
            for rule in rules {
                for problem in rule.check(item) {
                    problems.append(problem)
                }
            }
            return problems
        }

        func requireValid(_ item: RecallGroup) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.label()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [RecallGroup]) -> [String: [String]] {
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

    static func defaultRecallGroupValidator() -> RecallGroupValidator {
        return RecallGroupValidator(
            rules: [
                RecallGroupNameLengthRule(maxLength: 1000),
                RecallGroupTimezoneLengthRule(maxLength: 1000),
                RecallGroupVisitMinutesRangeRule(min: 16, max: 255),
                RecallGroupCodePrefixRule(prefix: "OPS"),
                RecallGroupRequiredCodeRule(message: "recall group needs an entry"),
            ]
        )
    }
}
