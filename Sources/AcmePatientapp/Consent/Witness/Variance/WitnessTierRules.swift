import AcmePlatform
import Foundation

extension Consent {
    /// A rule a witness tier must pass. Check returns its problems, or none.
    protocol WitnessTierRule {
        func check(_ item: WitnessTier) -> [String]
    }

    final class WitnessTierRequiredCodeRule: WitnessTierRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: WitnessTier) -> [String] {
            if item.code.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class WitnessTierCeilingRangeRule: WitnessTierRule {
        var min: Double
        var max: Double

        init(min: Double, max: Double) {
            self.min = min
            self.max = max
        }

        func check(_ item: WitnessTier) -> [String] {
            let value = item.ceiling
            if value < min || value > max {
                return ["ceiling \(value) is outside \(min) to \(max)"]
            }
            return []
        }
    }

    final class WitnessTierAllowedNameRule: WitnessTierRule {
        var allowed: [String]

        init(allowed: [String]) {
            self.allowed = allowed
        }

        func check(_ item: WitnessTier) -> [String] {
            if allowed.count == 0 {
                return []
            }
            if !allowed.contains(Kit.Text.normalize(item.name)) {
                return ["name \(item.name) is out of range"]
            }
            return []
        }
    }

    /// Runs every rule of a witness tier.
    final class WitnessTierValidator {
        var rules: [any WitnessTierRule]

        init(rules: [any WitnessTierRule]) {
            self.rules = rules
        }

        func validate(_ item: WitnessTier) -> [String] {
            var problems: [String] = []
            for rule in rules {
                for problem in rule.check(item) {
                    problems.append(problem)
                }
            }
            return problems
        }

        func requireValid(_ item: WitnessTier) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.label()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [WitnessTier]) -> [String: [String]] {
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

    static func defaultWitnessTierValidator() -> WitnessTierValidator {
        return WitnessTierValidator(
            rules: [
                WitnessTierRequiredCodeRule(message: "witness tier needs a value"),
                WitnessTierCeilingRangeRule(min: 5.7, max: 1699.1),
                WitnessTierAllowedNameRule(allowed: ["weighted"]),
            ]
        )
    }
}
