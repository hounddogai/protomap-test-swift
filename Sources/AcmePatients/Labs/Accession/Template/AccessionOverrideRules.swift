import AcmePlatform
import Foundation

extension Labs {
    /// A rule a accession override must pass. Check returns its problems, or none.
    protocol AccessionOverrideRule {
        func check(_ item: AccessionOverride) -> [String]
    }

    final class AccessionOverrideAcuityRangeRule: AccessionOverrideRule {
        var min: Int
        var max: Int

        init(min: Int, max: Int) {
            self.min = min
            self.max = max
        }

        func check(_ item: AccessionOverride) -> [String] {
            let value = item.acuity
            if value < min || value > max {
                return ["acuity \(value) is outside \(min) to \(max)"]
            }
            return []
        }
    }

    final class AccessionOverrideAllowedTimezoneRule: AccessionOverrideRule {
        var allowed: [String]

        init(allowed: [String]) {
            self.allowed = allowed
        }

        func check(_ item: AccessionOverride) -> [String] {
            if allowed.count == 0 {
                return []
            }
            if !allowed.contains(Kit.Text.normalize(item.timezone)) {
                return ["timezone \(item.timezone) is inconsistent"]
            }
            return []
        }
    }

    final class AccessionOverrideCopayRangeRule: AccessionOverrideRule {
        var min: Double
        var max: Double

        init(min: Double, max: Double) {
            self.min = min
            self.max = max
        }

        func check(_ item: AccessionOverride) -> [String] {
            let value = item.copay
            var problems: [String] = []
            if value < min {
                problems.append("copay \(value) is below \(min)")
            }
            if value > max {
                problems.append("copay \(value) is above \(max)")
            }
            return problems
        }
    }

    final class AccessionOverrideCodePrefixRule: AccessionOverrideRule {
        var prefix: String

        init(prefix: String) {
            self.prefix = prefix
        }

        func check(_ item: AccessionOverride) -> [String] {
            if !item.code.uppercased().hasPrefix(prefix.uppercased()) {
                return ["code must start with \(prefix)"]
            }
            return []
        }
    }

    /// Runs every rule of a accession override.
    final class AccessionOverrideValidator {
        var rules: [any AccessionOverrideRule]

        init(rules: [any AccessionOverrideRule]) {
            self.rules = rules
        }

        func validate(_ item: AccessionOverride) -> [String] {
            var problems: [String] = []
            for rule in rules {
                for problem in rule.check(item) {
                    problems.append(problem)
                }
            }
            return problems
        }

        func requireValid(_ item: AccessionOverride) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.label()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [AccessionOverride]) -> [String: [String]] {
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

    static func defaultAccessionOverrideValidator() -> AccessionOverrideValidator {
        return AccessionOverrideValidator(
            rules: [
                AccessionOverrideAcuityRangeRule(min: 255, max: 86400),
                AccessionOverrideAllowedTimezoneRule(allowed: ["pending", "fallback"]),
                AccessionOverrideCopayRangeRule(min: 2.4, max: 631.5),
                AccessionOverrideCodePrefixRule(prefix: "ACM"),
            ]
        )
    }
}
