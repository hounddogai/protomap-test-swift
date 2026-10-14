import AcmePlatform
import Foundation

extension ClinicalOps {
    /// A rule a global rounding claim must pass. Check returns its problems, or none.
    protocol GlobalRoundingClaimRule {
        func check(_ item: GlobalRoundingClaim) -> [String]
    }

    final class GlobalRoundingClaimRequiredOwnerIDRule: GlobalRoundingClaimRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: GlobalRoundingClaim) -> [String] {
            if item.ownerID.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class GlobalRoundingClaimFloorValueRangeRule: GlobalRoundingClaimRule {
        var min: Double
        var max: Double

        init(min: Double, max: Double) {
            self.min = min
            self.max = max
        }

        func check(_ item: GlobalRoundingClaim) -> [String] {
            let value = item.floorValue
            var problems: [String] = []
            if value < min {
                problems.append("floor value \(value) is below \(min)")
            }
            if value > max {
                problems.append("floor value \(value) is above \(max)")
            }
            return problems
        }
    }

    final class GlobalRoundingClaimCodeLengthRule: GlobalRoundingClaimRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: GlobalRoundingClaim) -> [String] {
            let size = item.code.count
            if size > maxLength {
                return ["code is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    /// Runs every rule of a global rounding claim.
    final class GlobalRoundingClaimValidator {
        var rules: [any GlobalRoundingClaimRule]

        init(rules: [any GlobalRoundingClaimRule]) {
            self.rules = rules
        }

        func validate(_ item: GlobalRoundingClaim) -> [String] {
            var problems: [String] = []
            for rule in rules {
                for problem in rule.check(item) {
                    problems.append(problem)
                }
            }
            return problems
        }

        func requireValid(_ item: GlobalRoundingClaim) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.displayLabel()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [GlobalRoundingClaim]) -> [String: [String]] {
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

    static func defaultGlobalRoundingClaimValidator() -> GlobalRoundingClaimValidator {
        return GlobalRoundingClaimValidator(
            rules: [
                GlobalRoundingClaimRequiredOwnerIDRule(message: "global rounding claim needs an entry"),
                GlobalRoundingClaimFloorValueRangeRule(min: 5.4, max: 4861.0),
                GlobalRoundingClaimCodeLengthRule(maxLength: 16),
            ]
        )
    }
}
