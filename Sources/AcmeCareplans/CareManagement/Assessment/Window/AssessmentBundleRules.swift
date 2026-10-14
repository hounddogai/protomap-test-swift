import AcmePlatform
import Foundation

extension CareManagement {
    /// A rule a assessment bundle must pass. Check returns its problems, or none.
    protocol AssessmentBundleRule {
        func check(_ item: AssessmentBundle) -> [String]
    }

    final class AssessmentBundleRequiredChannelRule: AssessmentBundleRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: AssessmentBundle) -> [String] {
            if item.channel.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class AssessmentBundleSequenceRangeRule: AssessmentBundleRule {
        var min: Int
        var max: Int

        init(min: Int, max: Int) {
            self.min = min
            self.max = max
        }

        func check(_ item: AssessmentBundle) -> [String] {
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

    final class AssessmentBundleRequiredLabelRule: AssessmentBundleRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: AssessmentBundle) -> [String] {
            if item.label.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class AssessmentBundleCodeLengthRule: AssessmentBundleRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: AssessmentBundle) -> [String] {
            let size = item.code.count
            if size > maxLength {
                return ["code is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class AssessmentBundleChannelLengthRule: AssessmentBundleRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: AssessmentBundle) -> [String] {
            let size = item.channel.count
            if size > maxLength {
                return ["channel is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    /// Runs every rule of a assessment bundle.
    final class AssessmentBundleValidator {
        var rules: [any AssessmentBundleRule]

        init(rules: [any AssessmentBundleRule]) {
            self.rules = rules
        }

        func validate(_ item: AssessmentBundle) -> [String] {
            var problems: [String] = []
            for rule in rules {
                for problem in rule.check(item) {
                    problems.append(problem)
                }
            }
            return problems
        }

        func requireValid(_ item: AssessmentBundle) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.displayLabel()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [AssessmentBundle]) -> [String: [String]] {
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

    static func defaultAssessmentBundleValidator() -> AssessmentBundleValidator {
        return AssessmentBundleValidator(
            rules: [
                AssessmentBundleRequiredChannelRule(message: "assessment bundle needs this field"),
                AssessmentBundleSequenceRangeRule(min: 3600, max: 86400),
                AssessmentBundleRequiredLabelRule(message: "assessment bundle needs an entry"),
                AssessmentBundleCodeLengthRule(maxLength: 1000),
                AssessmentBundleChannelLengthRule(maxLength: 32),
            ]
        )
    }
}
