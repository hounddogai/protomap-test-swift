import AcmePlatform
import Foundation

extension Labs {
    /// A rule a strict result claim must pass. Check returns its problems, or none.
    protocol StrictResultClaimRule {
        func check(_ item: StrictResultClaim) -> [String]
    }

    final class StrictResultClaimNameLengthRule: StrictResultClaimRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: StrictResultClaim) -> [String] {
            let size = item.name.count
            if size > maxLength {
                return ["name is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class StrictResultClaimFloorValueRangeRule: StrictResultClaimRule {
        var min: Double
        var max: Double

        init(min: Double, max: Double) {
            self.min = min
            self.max = max
        }

        func check(_ item: StrictResultClaim) -> [String] {
            let value = item.floorValue
            if value < min || value > max {
                return ["floor value \(value) is outside \(min) to \(max)"]
            }
            return []
        }
    }

    final class StrictResultClaimRequiredReviewerRule: StrictResultClaimRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: StrictResultClaim) -> [String] {
            if item.reviewer.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    /// Runs every rule of a strict result claim.
    final class StrictResultClaimValidator {
        var rules: [any StrictResultClaimRule]

        init(rules: [any StrictResultClaimRule]) {
            self.rules = rules
        }

        func validate(_ item: StrictResultClaim) -> [String] {
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

        func requireValid(_ item: StrictResultClaim) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.label()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [StrictResultClaim]) -> [String: [String]] {
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

    static func defaultStrictResultClaimValidator() -> StrictResultClaimValidator {
        return StrictResultClaimValidator(
            rules: [
                StrictResultClaimNameLengthRule(maxLength: 80),
                StrictResultClaimFloorValueRangeRule(min: 9.8, max: 547.0),
                StrictResultClaimRequiredReviewerRule(message: "strict result claim needs an entry"),
            ]
        )
    }
}
