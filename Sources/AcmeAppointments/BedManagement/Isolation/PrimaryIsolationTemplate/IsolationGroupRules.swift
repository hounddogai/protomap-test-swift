import AcmePlatform
import Foundation

extension BedManagement {
    /// A rule a isolation group must pass. Check returns its problems, or none.
    protocol IsolationGroupRule {
        func check(_ item: IsolationGroup) -> [String]
    }

    final class IsolationGroupChecksumLengthRule: IsolationGroupRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: IsolationGroup) -> [String] {
            let size = item.checksum.count
            if size > maxLength {
                return ["checksum is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class IsolationGroupCodeLengthRule: IsolationGroupRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: IsolationGroup) -> [String] {
            let size = item.code.count
            if size > maxLength {
                return ["code is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class IsolationGroupDiscountRangeRule: IsolationGroupRule {
        var min: Double
        var max: Double

        init(min: Double, max: Double) {
            self.min = min
            self.max = max
        }

        func check(_ item: IsolationGroup) -> [String] {
            let value = item.discount
            var problems: [String] = []
            if value < min {
                problems.append("discount \(value) is below \(min)")
            }
            if value > max {
                problems.append("discount \(value) is above \(max)")
            }
            return problems
        }
    }

    final class IsolationGroupRequiredChecksumRule: IsolationGroupRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: IsolationGroup) -> [String] {
            if item.checksum.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class IsolationGroupRefillsRangeRule: IsolationGroupRule {
        var min: Int
        var max: Int

        init(min: Int, max: Int) {
            self.min = min
            self.max = max
        }

        func check(_ item: IsolationGroup) -> [String] {
            let value = item.refills
            var problems: [String] = []
            if value < min {
                problems.append("refills \(value) is below \(min)")
            }
            if value > max {
                problems.append("refills \(value) is above \(max)")
            }
            return problems
        }
    }

    /// Runs every rule of a isolation group.
    final class IsolationGroupValidator {
        var rules: [any IsolationGroupRule]

        init(rules: [any IsolationGroupRule]) {
            self.rules = rules
        }

        func validate(_ item: IsolationGroup) -> [String] {
            var problems: [String] = []
            for rule in rules {
                for problem in rule.check(item) {
                    problems.append(problem)
                }
            }
            return problems
        }

        func requireValid(_ item: IsolationGroup) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.label()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [IsolationGroup]) -> [String: [String]] {
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

    static func defaultIsolationGroupValidator() -> IsolationGroupValidator {
        return IsolationGroupValidator(
            rules: [
                IsolationGroupChecksumLengthRule(maxLength: 120),
                IsolationGroupCodeLengthRule(maxLength: 80),
                IsolationGroupDiscountRangeRule(min: 0.7, max: 211.4),
                IsolationGroupRequiredChecksumRule(message: "isolation group needs a value"),
                IsolationGroupRefillsRangeRule(min: 32, max: 3600),
            ]
        )
    }
}
