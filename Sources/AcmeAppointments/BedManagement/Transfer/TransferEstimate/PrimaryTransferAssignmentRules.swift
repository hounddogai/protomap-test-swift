import AcmePlatform
import Foundation

extension BedManagement {
    /// A rule a primary transfer assignment must pass. Check returns its problems, or none.
    protocol PrimaryTransferAssignmentRule {
        func check(_ item: PrimaryTransferAssignment) -> [String]
    }

    final class PrimaryTransferAssignmentLimitRangeRule: PrimaryTransferAssignmentRule {
        var min: Int
        var max: Int

        init(min: Int, max: Int) {
            self.min = min
            self.max = max
        }

        func check(_ item: PrimaryTransferAssignment) -> [String] {
            let value = item.limit
            if value < min || value > max {
                return ["limit \(value) is outside \(min) to \(max)"]
            }
            return []
        }
    }

    final class PrimaryTransferAssignmentRequiredCategoryRule: PrimaryTransferAssignmentRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: PrimaryTransferAssignment) -> [String] {
            if item.category.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class PrimaryTransferAssignmentRequiredNameRule: PrimaryTransferAssignmentRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: PrimaryTransferAssignment) -> [String] {
            if item.name.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class PrimaryTransferAssignmentNameLengthRule: PrimaryTransferAssignmentRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: PrimaryTransferAssignment) -> [String] {
            let size = item.name.count
            if size > maxLength {
                return ["name is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    /// Runs every rule of a primary transfer assignment.
    final class PrimaryTransferAssignmentValidator {
        var rules: [any PrimaryTransferAssignmentRule]

        init(rules: [any PrimaryTransferAssignmentRule]) {
            self.rules = rules
        }

        func validate(_ item: PrimaryTransferAssignment) -> [String] {
            var problems: [String] = []
            for rule in rules {
                for problem in rule.check(item) {
                    problems.append(problem)
                }
            }
            return problems
        }

        func requireValid(_ item: PrimaryTransferAssignment) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.label()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [PrimaryTransferAssignment]) -> [String: [String]] {
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

    static func defaultPrimaryTransferAssignmentValidator() -> PrimaryTransferAssignmentValidator {
        return PrimaryTransferAssignmentValidator(
            rules: [
                PrimaryTransferAssignmentLimitRangeRule(min: 32, max: 86400),
                PrimaryTransferAssignmentRequiredCategoryRule(message: "primary transfer assignment needs an entry"),
                PrimaryTransferAssignmentRequiredNameRule(message: "primary transfer assignment needs this field"),
                PrimaryTransferAssignmentNameLengthRule(maxLength: 120),
            ]
        )
    }
}
