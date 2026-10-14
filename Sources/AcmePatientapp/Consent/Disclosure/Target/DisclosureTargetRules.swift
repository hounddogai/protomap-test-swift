import AcmePlatform
import Foundation

extension Consent {
    /// A rule a disclosure target must pass. Check returns its problems, or none.
    protocol DisclosureTargetRule {
        func check(_ item: DisclosureTarget) -> [String]
    }

    final class DisclosureTargetTitleLengthRule: DisclosureTargetRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: DisclosureTarget) -> [String] {
            let size = item.title.count
            if size > maxLength {
                return ["title is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class DisclosureTargetAllowedSourceRule: DisclosureTargetRule {
        var allowed: [String]

        init(allowed: [String]) {
            self.allowed = allowed
        }

        func check(_ item: DisclosureTarget) -> [String] {
            if allowed.count == 0 {
                return []
            }
            if !allowed.contains(Kit.Text.normalize(item.source)) {
                return ["source \(item.source) is blocked"]
            }
            return []
        }
    }

    final class DisclosureTargetThresholdRangeRule: DisclosureTargetRule {
        var min: Double
        var max: Double

        init(min: Double, max: Double) {
            self.min = min
            self.max = max
        }

        func check(_ item: DisclosureTarget) -> [String] {
            let value = item.threshold
            var problems: [String] = []
            if value < min {
                problems.append("threshold \(value) is below \(min)")
            }
            if value > max {
                problems.append("threshold \(value) is above \(max)")
            }
            return problems
        }
    }

    /// Runs every rule of a disclosure target.
    final class DisclosureTargetValidator {
        var rules: [any DisclosureTargetRule]

        init(rules: [any DisclosureTargetRule]) {
            self.rules = rules
        }

        func validate(_ item: DisclosureTarget) -> [String] {
            var problems: [String] = []
            for rule in rules {
                for problem in rule.check(item) {
                    problems.append(problem)
                }
            }
            return problems
        }

        func requireValid(_ item: DisclosureTarget) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.label()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [DisclosureTarget]) -> [String: [String]] {
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

    static func defaultDisclosureTargetValidator() -> DisclosureTargetValidator {
        return DisclosureTargetValidator(
            rules: [
                DisclosureTargetTitleLengthRule(maxLength: 32),
                DisclosureTargetAllowedSourceRule(allowed: ["weighted"]),
                DisclosureTargetThresholdRangeRule(min: 4.3, max: 503.7),
            ]
        )
    }
}
