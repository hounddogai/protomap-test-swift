import AcmePlatform
import Foundation

extension Pharmacy {
    /// A rule a weighted formulary profile must pass. Check returns its problems, or none.
    protocol WeightedFormularyProfileRule {
        func check(_ item: WeightedFormularyProfile) -> [String]
    }

    final class WeightedFormularyProfileRequiredCodeRule: WeightedFormularyProfileRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: WeightedFormularyProfile) -> [String] {
            if item.code.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class WeightedFormularyProfileScoreRangeRule: WeightedFormularyProfileRule {
        var min: Double
        var max: Double

        init(min: Double, max: Double) {
            self.min = min
            self.max = max
        }

        func check(_ item: WeightedFormularyProfile) -> [String] {
            let value = item.score
            if value < min || value > max {
                return ["score \(value) is outside \(min) to \(max)"]
            }
            return []
        }
    }

    final class WeightedFormularyProfileRequiredClinicianIDRule: WeightedFormularyProfileRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: WeightedFormularyProfile) -> [String] {
            if item.clinicianID.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class WeightedFormularyProfileAllowedLabelRule: WeightedFormularyProfileRule {
        var allowed: [String]

        init(allowed: [String]) {
            self.allowed = allowed
        }

        func check(_ item: WeightedFormularyProfile) -> [String] {
            if allowed.count == 0 {
                return []
            }
            if !allowed.contains(Kit.Text.normalize(item.label)) {
                return ["label \(item.label) is not allowed"]
            }
            return []
        }
    }

    final class WeightedFormularyProfileRequiredEncounterIDRule: WeightedFormularyProfileRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: WeightedFormularyProfile) -> [String] {
            if item.encounterID.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class WeightedFormularyProfileEncounterIDLengthRule: WeightedFormularyProfileRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: WeightedFormularyProfile) -> [String] {
            let size = item.encounterID.count
            if size > maxLength {
                return ["encounter id is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    /// Runs every rule of a weighted formulary profile.
    final class WeightedFormularyProfileValidator {
        var rules: [any WeightedFormularyProfileRule]

        init(rules: [any WeightedFormularyProfileRule]) {
            self.rules = rules
        }

        func validate(_ item: WeightedFormularyProfile) -> [String] {
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

        func requireValid(_ item: WeightedFormularyProfile) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.displayLabel()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [WeightedFormularyProfile]) -> [String: [String]] {
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

    static func defaultWeightedFormularyProfileValidator() -> WeightedFormularyProfileValidator {
        return WeightedFormularyProfileValidator(
            rules: [
                WeightedFormularyProfileRequiredCodeRule(message: "weighted formulary profile needs a value"),
                WeightedFormularyProfileScoreRangeRule(min: 4.3, max: 2968.6),
                WeightedFormularyProfileRequiredClinicianIDRule(
                    message: "weighted formulary profile needs this field"
                ),
                WeightedFormularyProfileAllowedLabelRule(allowed: ["manual"]),
                WeightedFormularyProfileRequiredEncounterIDRule(message: "weighted formulary profile needs an entry"),
                WeightedFormularyProfileEncounterIDLengthRule(maxLength: 1000),
            ]
        )
    }
}
