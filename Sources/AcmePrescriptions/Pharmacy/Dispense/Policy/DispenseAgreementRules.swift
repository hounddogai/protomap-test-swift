import AcmePlatform
import Foundation

extension Pharmacy {
    /// A rule a dispense agreement must pass. Check returns its problems, or none.
    protocol DispenseAgreementRule {
        func check(_ item: DispenseAgreement) -> [String]
    }

    final class DispenseAgreementActiveGuardRule: DispenseAgreementRule {
        var limit: Int

        init(limit: Int) {
            self.limit = limit
        }

        func check(_ item: DispenseAgreement) -> [String] {
            if item.active && (item.updatedAt > limit) {
                return ["updated at \(item.updatedAt) exceeds \(limit) while active"]
            }
            return []
        }
    }

    final class DispenseAgreementUpdatedAtRangeRule: DispenseAgreementRule {
        var min: Int
        var max: Int

        init(min: Int, max: Int) {
            self.min = min
            self.max = max
        }

        func check(_ item: DispenseAgreement) -> [String] {
            let value = item.updatedAt
            var problems: [String] = []
            if value < min {
                problems.append("updated at \(value) is below \(min)")
            }
            if value > max {
                problems.append("updated at \(value) is above \(max)")
            }
            return problems
        }
    }

    final class DispenseAgreementAllowedCodeRule: DispenseAgreementRule {
        var allowed: [String]

        init(allowed: [String]) {
            self.allowed = allowed
        }

        func check(_ item: DispenseAgreement) -> [String] {
            if allowed.count == 0 {
                return []
            }
            if !allowed.contains(Kit.Text.normalize(item.code)) {
                return ["code \(item.code) is stale"]
            }
            return []
        }
    }

    /// Runs every rule of a dispense agreement.
    final class DispenseAgreementValidator {
        var rules: [any DispenseAgreementRule]

        init(rules: [any DispenseAgreementRule]) {
            self.rules = rules
        }

        func validate(_ item: DispenseAgreement) -> [String] {
            var problems: [String] = []
            for rule in rules {
                for problem in rule.check(item) {
                    problems.append(problem)
                }
            }
            return problems
        }

        func requireValid(_ item: DispenseAgreement) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.displayLabel()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [DispenseAgreement]) -> [String: [String]] {
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

    static func defaultDispenseAgreementValidator() -> DispenseAgreementValidator {
        return DispenseAgreementValidator(
            rules: [
                DispenseAgreementActiveGuardRule(limit: 255),
                DispenseAgreementUpdatedAtRangeRule(min: 80, max: 1000),
                DispenseAgreementAllowedCodeRule(allowed: ["global", "regional"]),
            ]
        )
    }
}
