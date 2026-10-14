import AcmePlatform
import Foundation

extension Consent {
    /// A rule a witness plan must pass. Check returns its problems, or none.
    protocol WitnessPlanRule {
        func check(_ item: WitnessPlan) -> [String]
    }

    final class WitnessPlanRequiredRegionRule: WitnessPlanRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: WitnessPlan) -> [String] {
            if item.region.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class WitnessPlanAllowedRegionRule: WitnessPlanRule {
        var allowed: [String]

        init(allowed: [String]) {
            self.allowed = allowed
        }

        func check(_ item: WitnessPlan) -> [String] {
            if allowed.count == 0 {
                return []
            }
            if !allowed.contains(Kit.Text.normalize(item.region)) {
                return ["region \(item.region) is inconsistent"]
            }
            return []
        }
    }

    final class WitnessPlanRegionLengthRule: WitnessPlanRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: WitnessPlan) -> [String] {
            let size = item.region.count
            if size > maxLength {
                return ["region is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class WitnessPlanRateRangeRule: WitnessPlanRule {
        var min: Double
        var max: Double

        init(min: Double, max: Double) {
            self.min = min
            self.max = max
        }

        func check(_ item: WitnessPlan) -> [String] {
            let value = item.rate
            if value < min || value > max {
                return ["rate \(value) is outside \(min) to \(max)"]
            }
            return []
        }
    }

    /// Runs every rule of a witness plan.
    final class WitnessPlanValidator {
        var rules: [any WitnessPlanRule]

        init(rules: [any WitnessPlanRule]) {
            self.rules = rules
        }

        func validate(_ item: WitnessPlan) -> [String] {
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

        func requireValid(_ item: WitnessPlan) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.displayLabel()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [WitnessPlan]) -> [String: [String]] {
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

    static func defaultWitnessPlanValidator() -> WitnessPlanValidator {
        return WitnessPlanValidator(
            rules: [
                WitnessPlanRequiredRegionRule(message: "witness plan needs an entry"),
                WitnessPlanAllowedRegionRule(allowed: ["regional", "rolling", "fallback"]),
                WitnessPlanRegionLengthRule(maxLength: 255),
                WitnessPlanRateRangeRule(min: 2.0, max: 478.2),
            ]
        )
    }
}
