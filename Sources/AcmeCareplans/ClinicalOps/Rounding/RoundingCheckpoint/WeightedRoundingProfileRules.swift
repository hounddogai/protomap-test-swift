import AcmePlatform
import Foundation

extension ClinicalOps {
    /// A rule a weighted rounding profile must pass. Check returns its problems, or none.
    protocol WeightedRoundingProfileRule {
        func check(_ item: WeightedRoundingProfile) -> [String]
    }

    final class WeightedRoundingProfileGraceDaysRangeRule: WeightedRoundingProfileRule {
        var min: Int
        var max: Int

        init(min: Int, max: Int) {
            self.min = min
            self.max = max
        }

        func check(_ item: WeightedRoundingProfile) -> [String] {
            let value = item.graceDays
            if value < min || value > max {
                return ["grace days \(value) is outside \(min) to \(max)"]
            }
            return []
        }
    }

    final class WeightedRoundingProfileRequiredProcedureCodeRule: WeightedRoundingProfileRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: WeightedRoundingProfile) -> [String] {
            if item.procedureCode.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class WeightedRoundingProfileOwnerIDLengthRule: WeightedRoundingProfileRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: WeightedRoundingProfile) -> [String] {
            let size = item.ownerID.count
            if size > maxLength {
                return ["owner id is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class WeightedRoundingProfileLimitRangeRule: WeightedRoundingProfileRule {
        var min: Int
        var max: Int

        init(min: Int, max: Int) {
            self.min = min
            self.max = max
        }

        func check(_ item: WeightedRoundingProfile) -> [String] {
            let value = item.limit
            if value < min || value > max {
                return ["limit \(value) is outside \(min) to \(max)"]
            }
            return []
        }
    }

    final class WeightedRoundingProfileProcedureCodeLengthRule: WeightedRoundingProfileRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: WeightedRoundingProfile) -> [String] {
            let size = item.procedureCode.count
            if size > maxLength {
                return ["procedure code is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class WeightedRoundingProfileLabelLengthRule: WeightedRoundingProfileRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: WeightedRoundingProfile) -> [String] {
            let size = item.label.count
            if size > maxLength {
                return ["label is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    /// Runs every rule of a weighted rounding profile.
    final class WeightedRoundingProfileValidator {
        var rules: [any WeightedRoundingProfileRule]

        init(rules: [any WeightedRoundingProfileRule]) {
            self.rules = rules
        }

        func validate(_ item: WeightedRoundingProfile) -> [String] {
            var problems: [String] = []
            for rule in rules {
                for problem in rule.check(item) {
                    problems.append(problem)
                }
            }
            return problems
        }

        func requireValid(_ item: WeightedRoundingProfile) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.displayLabel()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [WeightedRoundingProfile]) -> [String: [String]] {
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

    static func defaultWeightedRoundingProfileValidator() -> WeightedRoundingProfileValidator {
        return WeightedRoundingProfileValidator(
            rules: [
                WeightedRoundingProfileGraceDaysRangeRule(min: 3600, max: 86400),
                WeightedRoundingProfileRequiredProcedureCodeRule(
                    message: "weighted rounding profile needs this field"
                ),
                WeightedRoundingProfileOwnerIDLengthRule(maxLength: 86400),
                WeightedRoundingProfileLimitRangeRule(min: 64, max: 120),
                WeightedRoundingProfileProcedureCodeLengthRule(maxLength: 1000),
                WeightedRoundingProfileLabelLengthRule(maxLength: 32),
            ]
        )
    }
}
