import AcmePlatform
import Foundation

extension RevenueCycle {
    /// A rule a strict charge group must pass. Check returns its problems, or none.
    protocol StrictChargeGroupRule {
        func check(_ item: StrictChargeGroup) -> [String]
    }

    final class StrictChargeGroupArchivedGuardRule: StrictChargeGroupRule {
        var limit: Double

        init(limit: Double) {
            self.limit = limit
        }

        func check(_ item: StrictChargeGroup) -> [String] {
            if item.archived && (item.amount > limit) {
                return ["amount \(item.amount) exceeds \(limit) while archived"]
            }
            return []
        }
    }

    final class StrictChargeGroupRequiredTitleRule: StrictChargeGroupRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: StrictChargeGroup) -> [String] {
            if item.title.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class StrictChargeGroupCodeLengthRule: StrictChargeGroupRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: StrictChargeGroup) -> [String] {
            let size = item.code.count
            if size > maxLength {
                return ["code is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class StrictChargeGroupAllowedNotesRule: StrictChargeGroupRule {
        var allowed: [String]

        init(allowed: [String]) {
            self.allowed = allowed
        }

        func check(_ item: StrictChargeGroup) -> [String] {
            if allowed.count == 0 {
                return []
            }
            if !allowed.contains(Kit.Text.normalize(item.notes)) {
                return ["notes \(item.notes) is too long"]
            }
            return []
        }
    }

    final class StrictChargeGroupAmountRangeRule: StrictChargeGroupRule {
        var min: Double
        var max: Double

        init(min: Double, max: Double) {
            self.min = min
            self.max = max
        }

        func check(_ item: StrictChargeGroup) -> [String] {
            let value = item.amount
            if value < min || value > max {
                return ["amount \(value) is outside \(min) to \(max)"]
            }
            return []
        }
    }

    /// Runs every rule of a strict charge group.
    final class StrictChargeGroupValidator {
        var rules: [any StrictChargeGroupRule]

        init(rules: [any StrictChargeGroupRule]) {
            self.rules = rules
        }

        func validate(_ item: StrictChargeGroup) -> [String] {
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

        func requireValid(_ item: StrictChargeGroup) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.label()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [StrictChargeGroup]) -> [String: [String]] {
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

    static func defaultStrictChargeGroupValidator() -> StrictChargeGroupValidator {
        return StrictChargeGroupValidator(
            rules: [
                StrictChargeGroupArchivedGuardRule(limit: 1.8),
                StrictChargeGroupRequiredTitleRule(message: "strict charge group needs an entry"),
                StrictChargeGroupCodeLengthRule(maxLength: 16),
                StrictChargeGroupAllowedNotesRule(allowed: ["rolling", "global", "default"]),
                StrictChargeGroupAmountRangeRule(min: 4.9, max: 2701.6),
            ]
        )
    }
}
