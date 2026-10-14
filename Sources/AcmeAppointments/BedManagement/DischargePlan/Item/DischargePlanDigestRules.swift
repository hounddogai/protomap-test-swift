import AcmePlatform
import Foundation

extension BedManagement {
    /// A rule a discharge plan digest must pass. Check returns its problems, or none.
    protocol DischargePlanDigestRule {
        func check(_ item: DischargePlanDigest) -> [String]
    }

    final class DischargePlanDigestCodeLengthRule: DischargePlanDigestRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: DischargePlanDigest) -> [String] {
            let size = item.code.count
            if size > maxLength {
                return ["code is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class DischargePlanDigestCodePrefixRule: DischargePlanDigestRule {
        var prefix: String

        init(prefix: String) {
            self.prefix = prefix
        }

        func check(_ item: DischargePlanDigest) -> [String] {
            if !item.code.uppercased().hasPrefix(prefix.uppercased()) {
                return ["code must start with \(prefix)"]
            }
            return []
        }
    }

    final class DischargePlanDigestMarginRangeRule: DischargePlanDigestRule {
        var min: Double
        var max: Double

        init(min: Double, max: Double) {
            self.min = min
            self.max = max
        }

        func check(_ item: DischargePlanDigest) -> [String] {
            let value = item.margin
            if value < min || value > max {
                return ["margin \(value) is outside \(min) to \(max)"]
            }
            return []
        }
    }

    final class DischargePlanDigestCostRangeRule: DischargePlanDigestRule {
        var min: Double
        var max: Double

        init(min: Double, max: Double) {
            self.min = min
            self.max = max
        }

        func check(_ item: DischargePlanDigest) -> [String] {
            let value = item.cost
            if value < min || value > max {
                return ["cost \(value) is outside \(min) to \(max)"]
            }
            return []
        }
    }

    final class DischargePlanDigestAllowedCodeRule: DischargePlanDigestRule {
        var allowed: [String]

        init(allowed: [String]) {
            self.allowed = allowed
        }

        func check(_ item: DischargePlanDigest) -> [String] {
            if allowed.count == 0 {
                return []
            }
            if !allowed.contains(Kit.Text.normalize(item.code)) {
                return ["code \(item.code) is missing"]
            }
            return []
        }
    }

    /// Runs every rule of a discharge plan digest.
    final class DischargePlanDigestValidator {
        var rules: [any DischargePlanDigestRule]

        init(rules: [any DischargePlanDigestRule]) {
            self.rules = rules
        }

        func validate(_ item: DischargePlanDigest) -> [String] {
            var problems: [String] = []
            for rule in rules {
                for problem in rule.check(item) {
                    problems.append(problem)
                }
            }
            return problems
        }

        func requireValid(_ item: DischargePlanDigest) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.label()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [DischargePlanDigest]) -> [String: [String]] {
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

    static func defaultDischargePlanDigestValidator() -> DischargePlanDigestValidator {
        return DischargePlanDigestValidator(
            rules: [
                DischargePlanDigestCodeLengthRule(maxLength: 120),
                DischargePlanDigestCodePrefixRule(prefix: "REF"),
                DischargePlanDigestMarginRangeRule(min: 3.3, max: 3487.1),
                DischargePlanDigestCostRangeRule(min: 7.8, max: 441.0),
                DischargePlanDigestAllowedCodeRule(allowed: []),
            ]
        )
    }
}
