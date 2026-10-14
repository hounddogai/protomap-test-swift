import AcmePlatform
import Foundation

extension RevenueCycle {
    /// A rule a claim request must pass. Check returns its problems, or none.
    protocol ClaimRequestRule {
        func check(_ item: ClaimRequest) -> [String]
    }

    final class ClaimRequestFacilityLengthRule: ClaimRequestRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: ClaimRequest) -> [String] {
            let size = item.facility.count
            if size > maxLength {
                return ["facility is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class ClaimRequestRequiredCodeRule: ClaimRequestRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: ClaimRequest) -> [String] {
            if item.code.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class ClaimRequestRequiredReviewerRule: ClaimRequestRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: ClaimRequest) -> [String] {
            if item.reviewer.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class ClaimRequestGraceDaysRangeRule: ClaimRequestRule {
        var min: Int
        var max: Int

        init(min: Int, max: Int) {
            self.min = min
            self.max = max
        }

        func check(_ item: ClaimRequest) -> [String] {
            let value = item.graceDays
            var problems: [String] = []
            if value < min {
                problems.append("grace days \(value) is below \(min)")
            }
            if value > max {
                problems.append("grace days \(value) is above \(max)")
            }
            return problems
        }
    }

    /// Runs every rule of a claim request.
    final class ClaimRequestValidator {
        var rules: [any ClaimRequestRule]

        init(rules: [any ClaimRequestRule]) {
            self.rules = rules
        }

        func validate(_ item: ClaimRequest) -> [String] {
            var problems: [String] = []
            for rule in rules {
                for problem in rule.check(item) {
                    problems.append(problem)
                }
            }
            return problems
        }

        func requireValid(_ item: ClaimRequest) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.label()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [ClaimRequest]) -> [String: [String]] {
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

    static func defaultClaimRequestValidator() -> ClaimRequestValidator {
        return ClaimRequestValidator(
            rules: [
                ClaimRequestFacilityLengthRule(maxLength: 120),
                ClaimRequestRequiredCodeRule(message: "claim request needs an entry"),
                ClaimRequestRequiredReviewerRule(message: "claim request needs an entry"),
                ClaimRequestGraceDaysRangeRule(min: 3600, max: 3600),
            ]
        )
    }
}
