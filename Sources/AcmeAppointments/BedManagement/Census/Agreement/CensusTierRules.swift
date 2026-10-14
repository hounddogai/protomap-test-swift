import AcmePlatform
import Foundation

extension BedManagement {
    /// A rule a census tier must pass. Check returns its problems, or none.
    protocol CensusTierRule {
        func check(_ item: CensusTier) -> [String]
    }

    final class CensusTierPinnedGuardRule: CensusTierRule {
        var limit: Int

        init(limit: Int) {
            self.limit = limit
        }

        func check(_ item: CensusTier) -> [String] {
            if item.pinned && (item.durationMinutes > limit) {
                return ["duration minutes \(item.durationMinutes) exceeds \(limit) while pinned"]
            }
            return []
        }
    }

    final class CensusTierRequiredNameRule: CensusTierRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: CensusTier) -> [String] {
            if item.name.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class CensusTierRequiredAllergyRule: CensusTierRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: CensusTier) -> [String] {
            if item.allergy.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class CensusTierExpiresAtRangeRule: CensusTierRule {
        var min: Int
        var max: Int

        init(min: Int, max: Int) {
            self.min = min
            self.max = max
        }

        func check(_ item: CensusTier) -> [String] {
            let value = item.expiresAt
            var problems: [String] = []
            if value < min {
                problems.append("expires at \(value) is below \(min)")
            }
            if value > max {
                problems.append("expires at \(value) is above \(max)")
            }
            return problems
        }
    }

    /// Runs every rule of a census tier.
    final class CensusTierValidator {
        var rules: [any CensusTierRule]

        init(rules: [any CensusTierRule]) {
            self.rules = rules
        }

        func validate(_ item: CensusTier) -> [String] {
            var problems: [String] = []
            for rule in rules {
                for problem in rule.check(item) {
                    problems.append(problem)
                }
            }
            return problems
        }

        func requireValid(_ item: CensusTier) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.displayLabel()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [CensusTier]) -> [String: [String]] {
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

    static func defaultCensusTierValidator() -> CensusTierValidator {
        return CensusTierValidator(
            rules: [
                CensusTierPinnedGuardRule(limit: 255),
                CensusTierRequiredNameRule(message: "census tier needs a value"),
                CensusTierRequiredAllergyRule(message: "census tier needs an entry"),
                CensusTierExpiresAtRangeRule(min: 255, max: 86400),
            ]
        )
    }
}
