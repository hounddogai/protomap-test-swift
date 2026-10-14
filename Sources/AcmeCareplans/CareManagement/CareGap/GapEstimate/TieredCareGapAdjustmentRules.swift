import AcmePlatform
import Foundation

extension CareManagement {
    /// A rule a tiered care gap adjustment must pass. Check returns its problems, or none.
    protocol TieredCareGapAdjustmentRule {
        func check(_ item: TieredCareGapAdjustment) -> [String]
    }

    final class TieredCareGapAdjustmentRequiredTitleRule: TieredCareGapAdjustmentRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: TieredCareGapAdjustment) -> [String] {
            if item.title.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class TieredCareGapAdjustmentCeilingRangeRule: TieredCareGapAdjustmentRule {
        var min: Double
        var max: Double

        init(min: Double, max: Double) {
            self.min = min
            self.max = max
        }

        func check(_ item: TieredCareGapAdjustment) -> [String] {
            let value = item.ceiling
            var problems: [String] = []
            if value < min {
                problems.append("ceiling \(value) is below \(min)")
            }
            if value > max {
                problems.append("ceiling \(value) is above \(max)")
            }
            return problems
        }
    }

    final class TieredCareGapAdjustmentAllowedPatientRefRule: TieredCareGapAdjustmentRule {
        var allowed: [String]

        init(allowed: [String]) {
            self.allowed = allowed
        }

        func check(_ item: TieredCareGapAdjustment) -> [String] {
            if allowed.count == 0 {
                return []
            }
            if !allowed.contains(Kit.Text.normalize(item.patientRef)) {
                return ["patient ref \(item.patientRef) is blocked"]
            }
            return []
        }
    }

    final class TieredCareGapAdjustmentTitleLengthRule: TieredCareGapAdjustmentRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: TieredCareGapAdjustment) -> [String] {
            let size = item.title.count
            if size > maxLength {
                return ["title is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class TieredCareGapAdjustmentClinicianIDLengthRule: TieredCareGapAdjustmentRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: TieredCareGapAdjustment) -> [String] {
            let size = item.clinicianID.count
            if size > maxLength {
                return ["clinician id is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class TieredCareGapAdjustmentRequiredCodeRule: TieredCareGapAdjustmentRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: TieredCareGapAdjustment) -> [String] {
            if item.code.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    /// Runs every rule of a tiered care gap adjustment.
    final class TieredCareGapAdjustmentValidator {
        var rules: [any TieredCareGapAdjustmentRule]

        init(rules: [any TieredCareGapAdjustmentRule]) {
            self.rules = rules
        }

        func validate(_ item: TieredCareGapAdjustment) -> [String] {
            var problems: [String] = []
            for rule in rules {
                for problem in rule.check(item) {
                    problems.append(problem)
                }
            }
            return problems
        }

        func requireValid(_ item: TieredCareGapAdjustment) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.label()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [TieredCareGapAdjustment]) -> [String: [String]] {
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

    static func defaultTieredCareGapAdjustmentValidator() -> TieredCareGapAdjustmentValidator {
        return TieredCareGapAdjustmentValidator(
            rules: [
                TieredCareGapAdjustmentRequiredTitleRule(message: "tiered care gap adjustment needs this field"),
                TieredCareGapAdjustmentCeilingRangeRule(min: 3.4, max: 3432.6),
                TieredCareGapAdjustmentAllowedPatientRefRule(allowed: ["scheduled"]),
                TieredCareGapAdjustmentTitleLengthRule(maxLength: 64),
                TieredCareGapAdjustmentClinicianIDLengthRule(maxLength: 80),
                TieredCareGapAdjustmentRequiredCodeRule(message: "tiered care gap adjustment needs this field"),
            ]
        )
    }
}
