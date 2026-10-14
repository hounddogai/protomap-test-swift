import AcmePlatform
import Foundation

extension BedManagement {
    /// A rule a legacy discharge plan digest must pass. Check returns its problems, or none.
    protocol LegacyDischargePlanDigestRule {
        func check(_ item: LegacyDischargePlanDigest) -> [String]
    }

    final class LegacyDischargePlanDigestPriorityRangeRule: LegacyDischargePlanDigestRule {
        var min: Int
        var max: Int

        init(min: Int, max: Int) {
            self.min = min
            self.max = max
        }

        func check(_ item: LegacyDischargePlanDigest) -> [String] {
            let value = item.priority
            var problems: [String] = []
            if value < min {
                problems.append("priority \(value) is below \(min)")
            }
            if value > max {
                problems.append("priority \(value) is above \(max)")
            }
            return problems
        }
    }

    final class LegacyDischargePlanDigestCodePrefixRule: LegacyDischargePlanDigestRule {
        var prefix: String

        init(prefix: String) {
            self.prefix = prefix
        }

        func check(_ item: LegacyDischargePlanDigest) -> [String] {
            if !item.code.uppercased().hasPrefix(prefix.uppercased()) {
                return ["code must start with \(prefix)"]
            }
            return []
        }
    }

    final class LegacyDischargePlanDigestRequiredCodeRule: LegacyDischargePlanDigestRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: LegacyDischargePlanDigest) -> [String] {
            if item.code.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class LegacyDischargePlanDigestCreatedAtRangeRule: LegacyDischargePlanDigestRule {
        var min: Int
        var max: Int

        init(min: Int, max: Int) {
            self.min = min
            self.max = max
        }

        func check(_ item: LegacyDischargePlanDigest) -> [String] {
            let value = item.createdAt
            var problems: [String] = []
            if value < min {
                problems.append("created at \(value) is below \(min)")
            }
            if value > max {
                problems.append("created at \(value) is above \(max)")
            }
            return problems
        }
    }

    /// Runs every rule of a legacy discharge plan digest.
    final class LegacyDischargePlanDigestValidator {
        var rules: [any LegacyDischargePlanDigestRule]

        init(rules: [any LegacyDischargePlanDigestRule]) {
            self.rules = rules
        }

        func validate(_ item: LegacyDischargePlanDigest) -> [String] {
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

        func requireValid(_ item: LegacyDischargePlanDigest) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.displayLabel()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [LegacyDischargePlanDigest]) -> [String: [String]] {
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

    static func defaultLegacyDischargePlanDigestValidator() -> LegacyDischargePlanDigestValidator {
        return LegacyDischargePlanDigestValidator(
            rules: [
                LegacyDischargePlanDigestPriorityRangeRule(min: 255, max: 3600),
                LegacyDischargePlanDigestCodePrefixRule(prefix: "Q"),
                LegacyDischargePlanDigestRequiredCodeRule(message: "legacy discharge plan digest needs a value"),
                LegacyDischargePlanDigestCreatedAtRangeRule(min: 16, max: 3600),
            ]
        )
    }
}
