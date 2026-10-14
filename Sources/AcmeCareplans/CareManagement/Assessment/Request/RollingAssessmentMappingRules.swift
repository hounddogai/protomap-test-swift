import AcmePlatform
import Foundation

extension CareManagement {
    /// A rule a rolling assessment mapping must pass. Check returns its problems, or none.
    protocol RollingAssessmentMappingRule {
        func check(_ item: RollingAssessmentMapping) -> [String]
    }

    final class RollingAssessmentMappingTitleLengthRule: RollingAssessmentMappingRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: RollingAssessmentMapping) -> [String] {
            let size = item.title.count
            if size > maxLength {
                return ["title is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class RollingAssessmentMappingNameLengthRule: RollingAssessmentMappingRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: RollingAssessmentMapping) -> [String] {
            let size = item.name.count
            if size > maxLength {
                return ["name is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class RollingAssessmentMappingCodeLengthRule: RollingAssessmentMappingRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: RollingAssessmentMapping) -> [String] {
            let size = item.code.count
            if size > maxLength {
                return ["code is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class RollingAssessmentMappingRequiredTitleRule: RollingAssessmentMappingRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: RollingAssessmentMapping) -> [String] {
            if item.title.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class RollingAssessmentMappingCodePrefixRule: RollingAssessmentMappingRule {
        var prefix: String

        init(prefix: String) {
            self.prefix = prefix
        }

        func check(_ item: RollingAssessmentMapping) -> [String] {
            if !item.code.uppercased().hasPrefix(prefix.uppercased()) {
                return ["code must start with \(prefix)"]
            }
            return []
        }
    }

    final class RollingAssessmentMappingFloorValueRangeRule: RollingAssessmentMappingRule {
        var min: Double
        var max: Double

        init(min: Double, max: Double) {
            self.min = min
            self.max = max
        }

        func check(_ item: RollingAssessmentMapping) -> [String] {
            let value = item.floorValue
            var problems: [String] = []
            if value < min {
                problems.append("floor value \(value) is below \(min)")
            }
            if value > max {
                problems.append("floor value \(value) is above \(max)")
            }
            return problems
        }
    }

    /// Runs every rule of a rolling assessment mapping.
    final class RollingAssessmentMappingValidator {
        var rules: [any RollingAssessmentMappingRule]

        init(rules: [any RollingAssessmentMappingRule]) {
            self.rules = rules
        }

        func validate(_ item: RollingAssessmentMapping) -> [String] {
            var problems: [String] = []
            for rule in rules {
                for problem in rule.check(item) {
                    problems.append(problem)
                }
            }
            return problems
        }

        func requireValid(_ item: RollingAssessmentMapping) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.label()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [RollingAssessmentMapping]) -> [String: [String]] {
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

    static func defaultRollingAssessmentMappingValidator() -> RollingAssessmentMappingValidator {
        return RollingAssessmentMappingValidator(
            rules: [
                RollingAssessmentMappingTitleLengthRule(maxLength: 16),
                RollingAssessmentMappingNameLengthRule(maxLength: 1000),
                RollingAssessmentMappingCodeLengthRule(maxLength: 3600),
                RollingAssessmentMappingRequiredTitleRule(message: "rolling assessment mapping needs an entry"),
                RollingAssessmentMappingCodePrefixRule(prefix: "OPS"),
                RollingAssessmentMappingFloorValueRangeRule(min: 5.2, max: 2848.2),
            ]
        )
    }
}
