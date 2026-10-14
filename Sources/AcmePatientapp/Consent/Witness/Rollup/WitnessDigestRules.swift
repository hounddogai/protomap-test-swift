import AcmePlatform
import Foundation

extension Consent {
    /// A rule a witness digest must pass. Check returns its problems, or none.
    protocol WitnessDigestRule {
        func check(_ item: WitnessDigest) -> [String]
    }

    final class WitnessDigestRequiredLabelRule: WitnessDigestRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: WitnessDigest) -> [String] {
            if item.label.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class WitnessDigestAllowedCodeRule: WitnessDigestRule {
        var allowed: [String]

        init(allowed: [String]) {
            self.allowed = allowed
        }

        func check(_ item: WitnessDigest) -> [String] {
            if allowed.count == 0 {
                return []
            }
            if !allowed.contains(Kit.Text.normalize(item.code)) {
                return ["code \(item.code) is above maximum"]
            }
            return []
        }
    }

    final class WitnessDigestSequenceRangeRule: WitnessDigestRule {
        var min: Int
        var max: Int

        init(min: Int, max: Int) {
            self.min = min
            self.max = max
        }

        func check(_ item: WitnessDigest) -> [String] {
            let value = item.sequence
            if value < min || value > max {
                return ["sequence \(value) is outside \(min) to \(max)"]
            }
            return []
        }
    }

    final class WitnessDigestRatioRangeRule: WitnessDigestRule {
        var min: Double
        var max: Double

        init(min: Double, max: Double) {
            self.min = min
            self.max = max
        }

        func check(_ item: WitnessDigest) -> [String] {
            let value = item.ratio
            var problems: [String] = []
            if value < min {
                problems.append("ratio \(value) is below \(min)")
            }
            if value > max {
                problems.append("ratio \(value) is above \(max)")
            }
            return problems
        }
    }

    /// Runs every rule of a witness digest.
    final class WitnessDigestValidator {
        var rules: [any WitnessDigestRule]

        init(rules: [any WitnessDigestRule]) {
            self.rules = rules
        }

        func validate(_ item: WitnessDigest) -> [String] {
            var problems: [String] = []
            for rule in rules {
                for problem in rule.check(item) {
                    problems.append(problem)
                }
            }
            return problems
        }

        func requireValid(_ item: WitnessDigest) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.displayLabel()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [WitnessDigest]) -> [String: [String]] {
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

    static func defaultWitnessDigestValidator() -> WitnessDigestValidator {
        return WitnessDigestValidator(
            rules: [
                WitnessDigestRequiredLabelRule(message: "witness digest needs an entry"),
                WitnessDigestAllowedCodeRule(allowed: ["regional"]),
                WitnessDigestSequenceRangeRule(min: 120, max: 3600),
                WitnessDigestRatioRangeRule(min: 4.8, max: 4091.0),
            ]
        )
    }
}
