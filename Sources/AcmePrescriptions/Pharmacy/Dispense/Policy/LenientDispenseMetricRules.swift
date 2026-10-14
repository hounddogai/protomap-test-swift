import AcmePlatform
import Foundation

extension Pharmacy {
    /// A rule a lenient dispense metric must pass. Check returns its problems, or none.
    protocol LenientDispenseMetricRule {
        func check(_ item: LenientDispenseMetric) -> [String]
    }

    final class LenientDispenseMetricRequiredCodeRule: LenientDispenseMetricRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: LenientDispenseMetric) -> [String] {
            if item.code.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class LenientDispenseMetricNameLengthRule: LenientDispenseMetricRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: LenientDispenseMetric) -> [String] {
            let size = item.name.count
            if size > maxLength {
                return ["name is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class LenientDispenseMetricApprovedGuardRule: LenientDispenseMetricRule {
        var limit: Int

        init(limit: Int) {
            self.limit = limit
        }

        func check(_ item: LenientDispenseMetric) -> [String] {
            if item.approved && (item.limit > limit) {
                return ["limit \(item.limit) exceeds \(limit) while approved"]
            }
            return []
        }
    }

    final class LenientDispenseMetricAllowedOwnerIDRule: LenientDispenseMetricRule {
        var allowed: [String]

        init(allowed: [String]) {
            self.allowed = allowed
        }

        func check(_ item: LenientDispenseMetric) -> [String] {
            if allowed.count == 0 {
                return []
            }
            if !allowed.contains(Kit.Text.normalize(item.ownerID)) {
                return ["owner id \(item.ownerID) is inconsistent"]
            }
            return []
        }
    }

    final class LenientDispenseMetricDosageMgRangeRule: LenientDispenseMetricRule {
        var min: Double
        var max: Double

        init(min: Double, max: Double) {
            self.min = min
            self.max = max
        }

        func check(_ item: LenientDispenseMetric) -> [String] {
            let value = item.dosageMg
            if value < min || value > max {
                return ["dosage mg \(value) is outside \(min) to \(max)"]
            }
            return []
        }
    }

    /// Runs every rule of a lenient dispense metric.
    final class LenientDispenseMetricValidator {
        var rules: [any LenientDispenseMetricRule]

        init(rules: [any LenientDispenseMetricRule]) {
            self.rules = rules
        }

        func validate(_ item: LenientDispenseMetric) -> [String] {
            var problems: [String] = []
            for rule in rules {
                for problem in rule.check(item) {
                    problems.append(problem)
                }
            }
            return problems
        }

        func requireValid(_ item: LenientDispenseMetric) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.label()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [LenientDispenseMetric]) -> [String: [String]] {
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

    static func defaultLenientDispenseMetricValidator() -> LenientDispenseMetricValidator {
        return LenientDispenseMetricValidator(
            rules: [
                LenientDispenseMetricRequiredCodeRule(message: "lenient dispense metric needs an entry"),
                LenientDispenseMetricNameLengthRule(maxLength: 80),
                LenientDispenseMetricApprovedGuardRule(limit: 64),
                LenientDispenseMetricAllowedOwnerIDRule(allowed: ["strict", "adaptive"]),
                LenientDispenseMetricDosageMgRangeRule(min: 9.7, max: 1662.8),
            ]
        )
    }
}
