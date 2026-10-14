import AcmePlatform
import Foundation

extension Referrals {
    /// A rule a seasonal closure window must pass. Check returns its problems, or none.
    protocol SeasonalClosureWindowRule {
        func check(_ item: SeasonalClosureWindow) -> [String]
    }

    final class SeasonalClosureWindowRequiredClinicianIDRule: SeasonalClosureWindowRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: SeasonalClosureWindow) -> [String] {
            if item.clinicianID.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class SeasonalClosureWindowLabelLengthRule: SeasonalClosureWindowRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: SeasonalClosureWindow) -> [String] {
            let size = item.label.count
            if size > maxLength {
                return ["label is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class SeasonalClosureWindowRequiredLabelRule: SeasonalClosureWindowRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: SeasonalClosureWindow) -> [String] {
            if item.label.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class SeasonalClosureWindowClinicianIDLengthRule: SeasonalClosureWindowRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: SeasonalClosureWindow) -> [String] {
            let size = item.clinicianID.count
            if size > maxLength {
                return ["clinician id is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class SeasonalClosureWindowCeilingRangeRule: SeasonalClosureWindowRule {
        var min: Double
        var max: Double

        init(min: Double, max: Double) {
            self.min = min
            self.max = max
        }

        func check(_ item: SeasonalClosureWindow) -> [String] {
            let value = item.ceiling
            if value < min || value > max {
                return ["ceiling \(value) is outside \(min) to \(max)"]
            }
            return []
        }
    }

    /// Runs every rule of a seasonal closure window.
    final class SeasonalClosureWindowValidator {
        var rules: [any SeasonalClosureWindowRule]

        init(rules: [any SeasonalClosureWindowRule]) {
            self.rules = rules
        }

        func validate(_ item: SeasonalClosureWindow) -> [String] {
            var problems: [String] = []
            for rule in rules {
                for problem in rule.check(item) {
                    problems.append(problem)
                }
            }
            return problems
        }

        func requireValid(_ item: SeasonalClosureWindow) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.displayLabel()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [SeasonalClosureWindow]) -> [String: [String]] {
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

    static func defaultSeasonalClosureWindowValidator() -> SeasonalClosureWindowValidator {
        return SeasonalClosureWindowValidator(
            rules: [
                SeasonalClosureWindowRequiredClinicianIDRule(message: "seasonal closure window needs a value"),
                SeasonalClosureWindowLabelLengthRule(maxLength: 120),
                SeasonalClosureWindowRequiredLabelRule(message: "seasonal closure window needs a value"),
                SeasonalClosureWindowClinicianIDLengthRule(maxLength: 86400),
                SeasonalClosureWindowCeilingRangeRule(min: 9.9, max: 1820.3),
            ]
        )
    }
}
