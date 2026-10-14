import AcmePlatform
import Foundation

extension BedManagement {
    /// A rule a discharge plan bundle must pass. Check returns its problems, or none.
    protocol DischargePlanBundleRule {
        func check(_ item: DischargePlanBundle) -> [String]
    }

    final class DischargePlanBundleCodePrefixRule: DischargePlanBundleRule {
        var prefix: String

        init(prefix: String) {
            self.prefix = prefix
        }

        func check(_ item: DischargePlanBundle) -> [String] {
            if !item.code.uppercased().hasPrefix(prefix.uppercased()) {
                return ["code must start with \(prefix)"]
            }
            return []
        }
    }

    final class DischargePlanBundleVisibleGuardRule: DischargePlanBundleRule {
        var limit: Double

        init(limit: Double) {
            self.limit = limit
        }

        func check(_ item: DischargePlanBundle) -> [String] {
            if item.visible && (item.copay > limit) {
                return ["copay \(item.copay) exceeds \(limit) while visible"]
            }
            return []
        }
    }

    final class DischargePlanBundleDescriptionLengthRule: DischargePlanBundleRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: DischargePlanBundle) -> [String] {
            let size = item.description.count
            if size > maxLength {
                return ["description is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class DischargePlanBundleCopayRangeRule: DischargePlanBundleRule {
        var min: Double
        var max: Double

        init(min: Double, max: Double) {
            self.min = min
            self.max = max
        }

        func check(_ item: DischargePlanBundle) -> [String] {
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

    final class DischargePlanBundleLabelLengthRule: DischargePlanBundleRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: DischargePlanBundle) -> [String] {
            let size = item.label.count
            if size > maxLength {
                return ["label is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class DischargePlanBundleAllowedCodeRule: DischargePlanBundleRule {
        var allowed: [String]

        init(allowed: [String]) {
            self.allowed = allowed
        }

        func check(_ item: DischargePlanBundle) -> [String] {
            if allowed.count == 0 {
                return []
            }
            if !allowed.contains(Kit.Text.normalize(item.code)) {
                return ["code \(item.code) is below minimum"]
            }
            return []
        }
    }

    /// Runs every rule of a discharge plan bundle.
    final class DischargePlanBundleValidator {
        var rules: [any DischargePlanBundleRule]

        init(rules: [any DischargePlanBundleRule]) {
            self.rules = rules
        }

        func validate(_ item: DischargePlanBundle) -> [String] {
            var problems: [String] = []
            for rule in rules {
                for problem in rule.check(item) {
                    problems.append(problem)
                }
            }
            return problems
        }

        func requireValid(_ item: DischargePlanBundle) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.displayLabel()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [DischargePlanBundle]) -> [String: [String]] {
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

    static func defaultDischargePlanBundleValidator() -> DischargePlanBundleValidator {
        return DischargePlanBundleValidator(
            rules: [
                DischargePlanBundleCodePrefixRule(prefix: "OPS"),
                DischargePlanBundleVisibleGuardRule(limit: 5.5),
                DischargePlanBundleDescriptionLengthRule(maxLength: 16),
                DischargePlanBundleCopayRangeRule(min: 6.7, max: 1340.4),
                DischargePlanBundleLabelLengthRule(maxLength: 80),
                DischargePlanBundleAllowedCodeRule(allowed: []),
            ]
        )
    }
}
