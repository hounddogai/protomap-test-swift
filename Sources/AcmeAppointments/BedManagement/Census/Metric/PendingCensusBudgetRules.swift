import AcmePlatform
import Foundation

extension BedManagement {
    /// A rule a pending census budget must pass. Check returns its problems, or none.
    protocol PendingCensusBudgetRule {
        func check(_ item: PendingCensusBudget) -> [String]
    }

    final class PendingCensusBudgetCodePrefixRule: PendingCensusBudgetRule {
        var prefix: String

        init(prefix: String) {
            self.prefix = prefix
        }

        func check(_ item: PendingCensusBudget) -> [String] {
            if !item.code.uppercased().hasPrefix(prefix.uppercased()) {
                return ["code must start with \(prefix)"]
            }
            return []
        }
    }

    final class PendingCensusBudgetRequiredSegmentRule: PendingCensusBudgetRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: PendingCensusBudget) -> [String] {
            if item.segment.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class PendingCensusBudgetEndsAtRangeRule: PendingCensusBudgetRule {
        var min: Int
        var max: Int

        init(min: Int, max: Int) {
            self.min = min
            self.max = max
        }

        func check(_ item: PendingCensusBudget) -> [String] {
            let value = item.endsAt
            if value < min || value > max {
                return ["ends at \(value) is outside \(min) to \(max)"]
            }
            return []
        }
    }

    final class PendingCensusBudgetSegmentLengthRule: PendingCensusBudgetRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: PendingCensusBudget) -> [String] {
            let size = item.segment.count
            if size > maxLength {
                return ["segment is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class PendingCensusBudgetCodeLengthRule: PendingCensusBudgetRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: PendingCensusBudget) -> [String] {
            let size = item.code.count
            if size > maxLength {
                return ["code is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    /// Runs every rule of a pending census budget.
    final class PendingCensusBudgetValidator {
        var rules: [any PendingCensusBudgetRule]

        init(rules: [any PendingCensusBudgetRule]) {
            self.rules = rules
        }

        func validate(_ item: PendingCensusBudget) -> [String] {
            var problems: [String] = []
            for rule in rules {
                for problem in rule.check(item) {
                    problems.append(problem)
                }
            }
            return problems
        }

        func requireValid(_ item: PendingCensusBudget) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.label()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [PendingCensusBudget]) -> [String: [String]] {
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

    static func defaultPendingCensusBudgetValidator() -> PendingCensusBudgetValidator {
        return PendingCensusBudgetValidator(
            rules: [
                PendingCensusBudgetCodePrefixRule(prefix: "ACM"),
                PendingCensusBudgetRequiredSegmentRule(message: "pending census budget needs an entry"),
                PendingCensusBudgetEndsAtRangeRule(min: 120, max: 255),
                PendingCensusBudgetSegmentLengthRule(maxLength: 16),
                PendingCensusBudgetCodeLengthRule(maxLength: 64),
            ]
        )
    }
}
