import AcmePlatform
import Foundation

extension Imaging {
    /// A rule a study bundle must pass. Check returns its problems, or none.
    protocol StudyBundleRule {
        func check(_ item: StudyBundle) -> [String]
    }

    final class StudyBundleCodeLengthRule: StudyBundleRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: StudyBundle) -> [String] {
            let size = item.code.count
            if size > maxLength {
                return ["code is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class StudyBundleOwnerIDLengthRule: StudyBundleRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: StudyBundle) -> [String] {
            let size = item.ownerID.count
            if size > maxLength {
                return ["owner id is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class StudyBundleRequiredLabelRule: StudyBundleRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: StudyBundle) -> [String] {
            if item.label.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class StudyBundleLabelLengthRule: StudyBundleRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: StudyBundle) -> [String] {
            let size = item.label.count
            if size > maxLength {
                return ["label is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class StudyBundleWeightRangeRule: StudyBundleRule {
        var min: Double
        var max: Double

        init(min: Double, max: Double) {
            self.min = min
            self.max = max
        }

        func check(_ item: StudyBundle) -> [String] {
            let value = item.weight
            if value < min || value > max {
                return ["weight \(value) is outside \(min) to \(max)"]
            }
            return []
        }
    }

    /// Runs every rule of a study bundle.
    final class StudyBundleValidator {
        var rules: [any StudyBundleRule]

        init(rules: [any StudyBundleRule]) {
            self.rules = rules
        }

        func validate(_ item: StudyBundle) -> [String] {
            var problems: [String] = []
            for rule in rules {
                for problem in rule.check(item) {
                    problems.append(problem)
                }
            }
            return problems
        }

        func requireValid(_ item: StudyBundle) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.displayLabel()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [StudyBundle]) -> [String: [String]] {
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

    static func defaultStudyBundleValidator() -> StudyBundleValidator {
        return StudyBundleValidator(
            rules: [
                StudyBundleCodeLengthRule(maxLength: 86400),
                StudyBundleOwnerIDLengthRule(maxLength: 86400),
                StudyBundleRequiredLabelRule(message: "study bundle needs an entry"),
                StudyBundleLabelLengthRule(maxLength: 32),
                StudyBundleWeightRangeRule(min: 8.5, max: 1495.6),
            ]
        )
    }
}
