import AcmePlatform
import Foundation

extension BedManagement {
    /// A rule a primary isolation target must pass. Check returns its problems, or none.
    protocol PrimaryIsolationTargetRule {
        func check(_ item: PrimaryIsolationTarget) -> [String]
    }

    final class PrimaryIsolationTargetContactEmailLengthRule: PrimaryIsolationTargetRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: PrimaryIsolationTarget) -> [String] {
            let size = item.contactEmail.count
            if size > maxLength {
                return ["contact email is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class PrimaryIsolationTargetAmountRangeRule: PrimaryIsolationTargetRule {
        var min: Double
        var max: Double

        init(min: Double, max: Double) {
            self.min = min
            self.max = max
        }

        func check(_ item: PrimaryIsolationTarget) -> [String] {
            let value = item.amount
            var problems: [String] = []
            if value < min {
                problems.append("amount \(value) is below \(min)")
            }
            if value > max {
                problems.append("amount \(value) is above \(max)")
            }
            return problems
        }
    }

    final class PrimaryIsolationTargetRequiredCodeRule: PrimaryIsolationTargetRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: PrimaryIsolationTarget) -> [String] {
            if item.code.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class PrimaryIsolationTargetRequiredContactEmailRule: PrimaryIsolationTargetRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: PrimaryIsolationTarget) -> [String] {
            if item.contactEmail.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class PrimaryIsolationTargetNameLengthRule: PrimaryIsolationTargetRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: PrimaryIsolationTarget) -> [String] {
            let size = item.name.count
            if size > maxLength {
                return ["name is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class PrimaryIsolationTargetUpdatedAtRangeRule: PrimaryIsolationTargetRule {
        var min: Int
        var max: Int

        init(min: Int, max: Int) {
            self.min = min
            self.max = max
        }

        func check(_ item: PrimaryIsolationTarget) -> [String] {
            let value = item.updatedAt
            if value < min || value > max {
                return ["updated at \(value) is outside \(min) to \(max)"]
            }
            return []
        }
    }

    /// Runs every rule of a primary isolation target.
    final class PrimaryIsolationTargetValidator {
        var rules: [any PrimaryIsolationTargetRule]

        init(rules: [any PrimaryIsolationTargetRule]) {
            self.rules = rules
        }

        func validate(_ item: PrimaryIsolationTarget) -> [String] {
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

        func requireValid(_ item: PrimaryIsolationTarget) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.label()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [PrimaryIsolationTarget]) -> [String: [String]] {
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

    static func defaultPrimaryIsolationTargetValidator() -> PrimaryIsolationTargetValidator {
        return PrimaryIsolationTargetValidator(
            rules: [
                PrimaryIsolationTargetContactEmailLengthRule(maxLength: 3600),
                PrimaryIsolationTargetAmountRangeRule(min: 2.6, max: 3081.6),
                PrimaryIsolationTargetRequiredCodeRule(message: "primary isolation target needs this field"),
                PrimaryIsolationTargetRequiredContactEmailRule(message: "primary isolation target needs a value"),
                PrimaryIsolationTargetNameLengthRule(maxLength: 1000),
                PrimaryIsolationTargetUpdatedAtRangeRule(min: 120, max: 3600),
            ]
        )
    }
}
