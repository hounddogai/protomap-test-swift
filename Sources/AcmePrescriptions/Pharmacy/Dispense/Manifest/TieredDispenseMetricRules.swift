import AcmePlatform
import Foundation

extension Pharmacy {
    /// A rule a tiered dispense metric must pass. Check returns its problems, or none.
    protocol TieredDispenseMetricRule {
        func check(_ item: TieredDispenseMetric) -> [String]
    }

    final class TieredDispenseMetricAllowedLabelRule: TieredDispenseMetricRule {
        var allowed: [String]

        init(allowed: [String]) {
            self.allowed = allowed
        }

        func check(_ item: TieredDispenseMetric) -> [String] {
            if allowed.count == 0 {
                return []
            }
            if !allowed.contains(Kit.Text.normalize(item.label)) {
                return ["label \(item.label) is above maximum"]
            }
            return []
        }
    }

    final class TieredDispenseMetricArchivedGuardRule: TieredDispenseMetricRule {
        var limit: Double

        init(limit: Double) {
            self.limit = limit
        }

        func check(_ item: TieredDispenseMetric) -> [String] {
            if item.archived && (item.rate > limit) {
                return ["rate \(item.rate) exceeds \(limit) while archived"]
            }
            return []
        }
    }

    final class TieredDispenseMetricRequiredExternalRefRule: TieredDispenseMetricRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: TieredDispenseMetric) -> [String] {
            if item.externalRef.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class TieredDispenseMetricRequiredLabelRule: TieredDispenseMetricRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: TieredDispenseMetric) -> [String] {
            if item.label.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class TieredDispenseMetricExternalRefLengthRule: TieredDispenseMetricRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: TieredDispenseMetric) -> [String] {
            let size = item.externalRef.count
            if size > maxLength {
                return ["external ref is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    /// Runs every rule of a tiered dispense metric.
    final class TieredDispenseMetricValidator {
        var rules: [any TieredDispenseMetricRule]

        init(rules: [any TieredDispenseMetricRule]) {
            self.rules = rules
        }

        func validate(_ item: TieredDispenseMetric) -> [String] {
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

        func requireValid(_ item: TieredDispenseMetric) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.displayLabel()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [TieredDispenseMetric]) -> [String: [String]] {
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

    static func defaultTieredDispenseMetricValidator() -> TieredDispenseMetricValidator {
        return TieredDispenseMetricValidator(
            rules: [
                TieredDispenseMetricAllowedLabelRule(allowed: []),
                TieredDispenseMetricArchivedGuardRule(limit: 1.2),
                TieredDispenseMetricRequiredExternalRefRule(message: "tiered dispense metric needs a value"),
                TieredDispenseMetricRequiredLabelRule(message: "tiered dispense metric needs an entry"),
                TieredDispenseMetricExternalRefLengthRule(maxLength: 3600),
            ]
        )
    }
}
