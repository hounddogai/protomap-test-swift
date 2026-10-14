import AcmePlatform
import Foundation

extension Pharmacy {
    /// A rule a global formulary baseline must pass. Check returns its problems, or none.
    protocol GlobalFormularyBaselineRule {
        func check(_ item: GlobalFormularyBaseline) -> [String]
    }

    final class GlobalFormularyBaselineCodeLengthRule: GlobalFormularyBaselineRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: GlobalFormularyBaseline) -> [String] {
            let size = item.code.count
            if size > maxLength {
                return ["code is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class GlobalFormularyBaselineVisibleGuardRule: GlobalFormularyBaselineRule {
        var limit: Double

        init(limit: Double) {
            self.limit = limit
        }

        func check(_ item: GlobalFormularyBaseline) -> [String] {
            if item.visible && (item.threshold > limit) {
                return ["threshold \(item.threshold) exceeds \(limit) while visible"]
            }
            return []
        }
    }

    final class GlobalFormularyBaselineThresholdRangeRule: GlobalFormularyBaselineRule {
        var min: Double
        var max: Double

        init(min: Double, max: Double) {
            self.min = min
            self.max = max
        }

        func check(_ item: GlobalFormularyBaseline) -> [String] {
            let value = item.threshold
            if value < min || value > max {
                return ["threshold \(value) is outside \(min) to \(max)"]
            }
            return []
        }
    }

    final class GlobalFormularyBaselineWeightRangeRule: GlobalFormularyBaselineRule {
        var min: Double
        var max: Double

        init(min: Double, max: Double) {
            self.min = min
            self.max = max
        }

        func check(_ item: GlobalFormularyBaseline) -> [String] {
            let value = item.weight
            if value < min || value > max {
                return ["weight \(value) is outside \(min) to \(max)"]
            }
            return []
        }
    }

    final class GlobalFormularyBaselineRequiredCodeRule: GlobalFormularyBaselineRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: GlobalFormularyBaseline) -> [String] {
            if item.code.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class GlobalFormularyBaselineRequiredClinicianIDRule: GlobalFormularyBaselineRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: GlobalFormularyBaseline) -> [String] {
            if item.clinicianID.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    /// Runs every rule of a global formulary baseline.
    final class GlobalFormularyBaselineValidator {
        var rules: [any GlobalFormularyBaselineRule]

        init(rules: [any GlobalFormularyBaselineRule]) {
            self.rules = rules
        }

        func validate(_ item: GlobalFormularyBaseline) -> [String] {
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

        func requireValid(_ item: GlobalFormularyBaseline) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.displayLabel()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [GlobalFormularyBaseline]) -> [String: [String]] {
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

    static func defaultGlobalFormularyBaselineValidator() -> GlobalFormularyBaselineValidator {
        return GlobalFormularyBaselineValidator(
            rules: [
                GlobalFormularyBaselineCodeLengthRule(maxLength: 80),
                GlobalFormularyBaselineVisibleGuardRule(limit: 2.5),
                GlobalFormularyBaselineThresholdRangeRule(min: 8.6, max: 916.5),
                GlobalFormularyBaselineWeightRangeRule(min: 8.2, max: 4891.4),
                GlobalFormularyBaselineRequiredCodeRule(message: "global formulary baseline needs a value"),
                GlobalFormularyBaselineRequiredClinicianIDRule(message: "global formulary baseline needs a value"),
            ]
        )
    }
}
