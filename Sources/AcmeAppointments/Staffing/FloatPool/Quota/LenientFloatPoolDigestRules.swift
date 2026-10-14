import AcmePlatform
import Foundation

extension Staffing {
    /// A rule a lenient float pool digest must pass. Check returns its problems, or none.
    protocol LenientFloatPoolDigestRule {
        func check(_ item: LenientFloatPoolDigest) -> [String]
    }

    final class LenientFloatPoolDigestRequiredCodeRule: LenientFloatPoolDigestRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: LenientFloatPoolDigest) -> [String] {
            if item.code.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class LenientFloatPoolDigestAllowedCodeRule: LenientFloatPoolDigestRule {
        var allowed: [String]

        init(allowed: [String]) {
            self.allowed = allowed
        }

        func check(_ item: LenientFloatPoolDigest) -> [String] {
            if allowed.count == 0 {
                return []
            }
            if !allowed.contains(Kit.Text.normalize(item.code)) {
                return ["code \(item.code) is blocked"]
            }
            return []
        }
    }

    final class LenientFloatPoolDigestSequenceRangeRule: LenientFloatPoolDigestRule {
        var min: Int
        var max: Int

        init(min: Int, max: Int) {
            self.min = min
            self.max = max
        }

        func check(_ item: LenientFloatPoolDigest) -> [String] {
            let value = item.sequence
            var problems: [String] = []
            if value < min {
                problems.append("sequence \(value) is below \(min)")
            }
            if value > max {
                problems.append("sequence \(value) is above \(max)")
            }
            return problems
        }
    }

    /// Runs every rule of a lenient float pool digest.
    final class LenientFloatPoolDigestValidator {
        var rules: [any LenientFloatPoolDigestRule]

        init(rules: [any LenientFloatPoolDigestRule]) {
            self.rules = rules
        }

        func validate(_ item: LenientFloatPoolDigest) -> [String] {
            var problems: [String] = []
            for rule in rules {
                for problem in rule.check(item) {
                    problems.append(problem)
                }
            }
            return problems
        }

        func requireValid(_ item: LenientFloatPoolDigest) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.label()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [LenientFloatPoolDigest]) -> [String: [String]] {
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

    static func defaultLenientFloatPoolDigestValidator() -> LenientFloatPoolDigestValidator {
        return LenientFloatPoolDigestValidator(
            rules: [
                LenientFloatPoolDigestRequiredCodeRule(message: "lenient float pool digest needs this field"),
                LenientFloatPoolDigestAllowedCodeRule(allowed: ["primary", "global", "lenient"]),
                LenientFloatPoolDigestSequenceRangeRule(min: 32, max: 80),
            ]
        )
    }
}
