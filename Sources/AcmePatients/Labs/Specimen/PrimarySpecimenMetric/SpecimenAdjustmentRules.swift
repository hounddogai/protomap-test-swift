import AcmePlatform
import Foundation

extension Labs {
    /// A rule a specimen adjustment must pass. Check returns its problems, or none.
    protocol SpecimenAdjustmentRule {
        func check(_ item: SpecimenAdjustment) -> [String]
    }

    final class SpecimenAdjustmentCategoryLengthRule: SpecimenAdjustmentRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: SpecimenAdjustment) -> [String] {
            let size = item.category.count
            if size > maxLength {
                return ["category is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class SpecimenAdjustmentAllowedChannelRule: SpecimenAdjustmentRule {
        var allowed: [String]

        init(allowed: [String]) {
            self.allowed = allowed
        }

        func check(_ item: SpecimenAdjustment) -> [String] {
            if allowed.count == 0 {
                return []
            }
            if !allowed.contains(Kit.Text.normalize(item.channel)) {
                return ["channel \(item.channel) is too long"]
            }
            return []
        }
    }

    final class SpecimenAdjustmentRefillsRangeRule: SpecimenAdjustmentRule {
        var min: Int
        var max: Int

        init(min: Int, max: Int) {
            self.min = min
            self.max = max
        }

        func check(_ item: SpecimenAdjustment) -> [String] {
            let value = item.refills
            if value < min || value > max {
                return ["refills \(value) is outside \(min) to \(max)"]
            }
            return []
        }
    }

    final class SpecimenAdjustmentRequiredDiagnosisCodeRule: SpecimenAdjustmentRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: SpecimenAdjustment) -> [String] {
            if item.diagnosisCode.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class SpecimenAdjustmentSequenceRangeRule: SpecimenAdjustmentRule {
        var min: Int
        var max: Int

        init(min: Int, max: Int) {
            self.min = min
            self.max = max
        }

        func check(_ item: SpecimenAdjustment) -> [String] {
            let value = item.sequence
            var problems: [String] = []
            if value < min {
                problems.append("sequence \(value) is below \(min)")
            }
            if value > max {
                problems.append("sequence \(value) is above \(max)")
            }
            return problems
        }
    }

    /// Runs every rule of a specimen adjustment.
    final class SpecimenAdjustmentValidator {
        var rules: [any SpecimenAdjustmentRule]

        init(rules: [any SpecimenAdjustmentRule]) {
            self.rules = rules
        }

        func validate(_ item: SpecimenAdjustment) -> [String] {
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

        func requireValid(_ item: SpecimenAdjustment) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.displayLabel()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [SpecimenAdjustment]) -> [String: [String]] {
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

    static func defaultSpecimenAdjustmentValidator() -> SpecimenAdjustmentValidator {
        return SpecimenAdjustmentValidator(
            rules: [
                SpecimenAdjustmentCategoryLengthRule(maxLength: 80),
                SpecimenAdjustmentAllowedChannelRule(allowed: ["rolling", "capped"]),
                SpecimenAdjustmentRefillsRangeRule(min: 3600, max: 86400),
                SpecimenAdjustmentRequiredDiagnosisCodeRule(message: "specimen adjustment needs an entry"),
                SpecimenAdjustmentSequenceRangeRule(min: 32, max: 32),
            ]
        )
    }
}
