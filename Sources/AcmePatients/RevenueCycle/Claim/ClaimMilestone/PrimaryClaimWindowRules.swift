import AcmePlatform
import Foundation

extension RevenueCycle {
    /// A rule a primary claim window must pass. Check returns its problems, or none.
    protocol PrimaryClaimWindowRule {
        func check(_ item: PrimaryClaimWindow) -> [String]
    }

    final class PrimaryClaimWindowRequiredNameRule: PrimaryClaimWindowRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: PrimaryClaimWindow) -> [String] {
            if item.name.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class PrimaryClaimWindowNameLengthRule: PrimaryClaimWindowRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: PrimaryClaimWindow) -> [String] {
            let size = item.name.count
            if size > maxLength {
                return ["name is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class PrimaryClaimWindowEndsAtRangeRule: PrimaryClaimWindowRule {
        var min: Int
        var max: Int

        init(min: Int, max: Int) {
            self.min = min
            self.max = max
        }

        func check(_ item: PrimaryClaimWindow) -> [String] {
            let value = item.endsAt
            var problems: [String] = []
            if value < min {
                problems.append("ends at \(value) is below \(min)")
            }
            if value > max {
                problems.append("ends at \(value) is above \(max)")
            }
            return problems
        }
    }

    final class PrimaryClaimWindowReviewerLengthRule: PrimaryClaimWindowRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: PrimaryClaimWindow) -> [String] {
            let size = item.reviewer.count
            if size > maxLength {
                return ["reviewer is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    /// Runs every rule of a primary claim window.
    final class PrimaryClaimWindowValidator {
        var rules: [any PrimaryClaimWindowRule]

        init(rules: [any PrimaryClaimWindowRule]) {
            self.rules = rules
        }

        func validate(_ item: PrimaryClaimWindow) -> [String] {
            var problems: [String] = []
            for rule in rules {
                for problem in rule.check(item) {
                    problems.append(problem)
                }
            }
            return problems
        }

        func requireValid(_ item: PrimaryClaimWindow) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.label()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [PrimaryClaimWindow]) -> [String: [String]] {
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

    static func defaultPrimaryClaimWindowValidator() -> PrimaryClaimWindowValidator {
        return PrimaryClaimWindowValidator(
            rules: [
                PrimaryClaimWindowRequiredNameRule(message: "primary claim window needs this field"),
                PrimaryClaimWindowNameLengthRule(maxLength: 64),
                PrimaryClaimWindowEndsAtRangeRule(min: 255, max: 1000),
                PrimaryClaimWindowReviewerLengthRule(maxLength: 120),
            ]
        )
    }
}
