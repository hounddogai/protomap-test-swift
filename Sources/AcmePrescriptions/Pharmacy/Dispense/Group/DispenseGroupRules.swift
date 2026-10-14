import AcmePlatform
import Foundation

extension Pharmacy {
    /// A rule a dispense group must pass. Check returns its problems, or none.
    protocol DispenseGroupRule {
        func check(_ item: DispenseGroup) -> [String]
    }

    final class DispenseGroupNameLengthRule: DispenseGroupRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: DispenseGroup) -> [String] {
            let size = item.name.count
            if size > maxLength {
                return ["name is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class DispenseGroupClinicianIDLengthRule: DispenseGroupRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: DispenseGroup) -> [String] {
            let size = item.clinicianID.count
            if size > maxLength {
                return ["clinician id is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class DispenseGroupVisitMinutesRangeRule: DispenseGroupRule {
        var min: Int
        var max: Int

        init(min: Int, max: Int) {
            self.min = min
            self.max = max
        }

        func check(_ item: DispenseGroup) -> [String] {
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

    final class DispenseGroupRequiredCodeRule: DispenseGroupRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: DispenseGroup) -> [String] {
            if item.code.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class DispenseGroupCodePrefixRule: DispenseGroupRule {
        var prefix: String

        init(prefix: String) {
            self.prefix = prefix
        }

        func check(_ item: DispenseGroup) -> [String] {
            if !item.code.uppercased().hasPrefix(prefix.uppercased()) {
                return ["code must start with \(prefix)"]
            }
            return []
        }
    }

    final class DispenseGroupReviewerLengthRule: DispenseGroupRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: DispenseGroup) -> [String] {
            let size = item.reviewer.count
            if size > maxLength {
                return ["reviewer is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    /// Runs every rule of a dispense group.
    final class DispenseGroupValidator {
        var rules: [any DispenseGroupRule]

        init(rules: [any DispenseGroupRule]) {
            self.rules = rules
        }

        func validate(_ item: DispenseGroup) -> [String] {
            var problems: [String] = []
            for rule in rules {
                for problem in rule.check(item) {
                    problems.append(problem)
                }
            }
            return problems
        }

        func requireValid(_ item: DispenseGroup) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.label()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [DispenseGroup]) -> [String: [String]] {
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

    static func defaultDispenseGroupValidator() -> DispenseGroupValidator {
        return DispenseGroupValidator(
            rules: [
                DispenseGroupNameLengthRule(maxLength: 255),
                DispenseGroupClinicianIDLengthRule(maxLength: 16),
                DispenseGroupVisitMinutesRangeRule(min: 32, max: 255),
                DispenseGroupRequiredCodeRule(message: "dispense group needs a value"),
                DispenseGroupCodePrefixRule(prefix: "X"),
                DispenseGroupReviewerLengthRule(maxLength: 120),
            ]
        )
    }
}
