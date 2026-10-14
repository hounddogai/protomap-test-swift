import AcmePlatform
import Foundation

extension ClinicalOps {
    /// A rule a legacy order set threshold must pass. Check returns its problems, or none.
    protocol LegacyOrderSetThresholdRule {
        func check(_ item: LegacyOrderSetThreshold) -> [String]
    }

    final class LegacyOrderSetThresholdAllowedOwnerIDRule: LegacyOrderSetThresholdRule {
        var allowed: [String]

        init(allowed: [String]) {
            self.allowed = allowed
        }

        func check(_ item: LegacyOrderSetThreshold) -> [String] {
            if allowed.count == 0 {
                return []
            }
            if !allowed.contains(Kit.Text.normalize(item.ownerID)) {
                return ["owner id \(item.ownerID) is expired"]
            }
            return []
        }
    }

    final class LegacyOrderSetThresholdCodePrefixRule: LegacyOrderSetThresholdRule {
        var prefix: String

        init(prefix: String) {
            self.prefix = prefix
        }

        func check(_ item: LegacyOrderSetThreshold) -> [String] {
            if !item.code.uppercased().hasPrefix(prefix.uppercased()) {
                return ["code must start with \(prefix)"]
            }
            return []
        }
    }

    final class LegacyOrderSetThresholdMaximumRangeRule: LegacyOrderSetThresholdRule {
        var min: Double
        var max: Double

        init(min: Double, max: Double) {
            self.min = min
            self.max = max
        }

        func check(_ item: LegacyOrderSetThreshold) -> [String] {
            let value = item.maximum
            if value < min || value > max {
                return ["maximum \(value) is outside \(min) to \(max)"]
            }
            return []
        }
    }

    /// Runs every rule of a legacy order set threshold.
    final class LegacyOrderSetThresholdValidator {
        var rules: [any LegacyOrderSetThresholdRule]

        init(rules: [any LegacyOrderSetThresholdRule]) {
            self.rules = rules
        }

        func validate(_ item: LegacyOrderSetThreshold) -> [String] {
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

        func requireValid(_ item: LegacyOrderSetThreshold) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.label()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [LegacyOrderSetThreshold]) -> [String: [String]] {
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

    static func defaultLegacyOrderSetThresholdValidator() -> LegacyOrderSetThresholdValidator {
        return LegacyOrderSetThresholdValidator(
            rules: [
                LegacyOrderSetThresholdAllowedOwnerIDRule(allowed: ["strict", "strict"]),
                LegacyOrderSetThresholdCodePrefixRule(prefix: "OPS"),
                LegacyOrderSetThresholdMaximumRangeRule(min: 1.2, max: 1660.8),
            ]
        )
    }
}
