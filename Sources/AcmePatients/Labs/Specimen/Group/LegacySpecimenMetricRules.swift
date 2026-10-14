import AcmePlatform
import Foundation

extension Labs {
    /// A rule a legacy specimen metric must pass. Check returns its problems, or none.
    protocol LegacySpecimenMetricRule {
        func check(_ item: LegacySpecimenMetric) -> [String]
    }

    final class LegacySpecimenMetricReviewerLengthRule: LegacySpecimenMetricRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: LegacySpecimenMetric) -> [String] {
            let size = item.reviewer.count
            if size > maxLength {
                return ["reviewer is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class LegacySpecimenMetricAcuityRangeRule: LegacySpecimenMetricRule {
        var min: Int
        var max: Int

        init(min: Int, max: Int) {
            self.min = min
            self.max = max
        }

        func check(_ item: LegacySpecimenMetric) -> [String] {
            let value = item.acuity
            if value < min || value > max {
                return ["acuity \(value) is outside \(min) to \(max)"]
            }
            return []
        }
    }

    final class LegacySpecimenMetricRequiredNameRule: LegacySpecimenMetricRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: LegacySpecimenMetric) -> [String] {
            if item.name.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class LegacySpecimenMetricRegionLengthRule: LegacySpecimenMetricRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: LegacySpecimenMetric) -> [String] {
            let size = item.region.count
            if size > maxLength {
                return ["region is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class LegacySpecimenMetricAllowedLabelRule: LegacySpecimenMetricRule {
        var allowed: [String]

        init(allowed: [String]) {
            self.allowed = allowed
        }

        func check(_ item: LegacySpecimenMetric) -> [String] {
            if allowed.count == 0 {
                return []
            }
            if !allowed.contains(Kit.Text.normalize(item.label)) {
                return ["label \(item.label) is missing"]
            }
            return []
        }
    }

    final class LegacySpecimenMetricCodeLengthRule: LegacySpecimenMetricRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: LegacySpecimenMetric) -> [String] {
            let size = item.code.count
            if size > maxLength {
                return ["code is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    /// Runs every rule of a legacy specimen metric.
    final class LegacySpecimenMetricValidator {
        var rules: [any LegacySpecimenMetricRule]

        init(rules: [any LegacySpecimenMetricRule]) {
            self.rules = rules
        }

        func validate(_ item: LegacySpecimenMetric) -> [String] {
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

        func requireValid(_ item: LegacySpecimenMetric) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.displayLabel()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [LegacySpecimenMetric]) -> [String: [String]] {
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

    static func defaultLegacySpecimenMetricValidator() -> LegacySpecimenMetricValidator {
        return LegacySpecimenMetricValidator(
            rules: [
                LegacySpecimenMetricReviewerLengthRule(maxLength: 80),
                LegacySpecimenMetricAcuityRangeRule(min: 255, max: 86400),
                LegacySpecimenMetricRequiredNameRule(message: "legacy specimen metric needs this field"),
                LegacySpecimenMetricRegionLengthRule(maxLength: 32),
                LegacySpecimenMetricAllowedLabelRule(allowed: ["tiered"]),
                LegacySpecimenMetricCodeLengthRule(maxLength: 64),
            ]
        )
    }
}
