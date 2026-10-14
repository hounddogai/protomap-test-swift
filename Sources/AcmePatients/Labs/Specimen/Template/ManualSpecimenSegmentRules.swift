import AcmePlatform
import Foundation

extension Labs {
    /// A rule a manual specimen segment must pass. Check returns its problems, or none.
    protocol ManualSpecimenSegmentRule {
        func check(_ item: ManualSpecimenSegment) -> [String]
    }

    final class ManualSpecimenSegmentCodeLengthRule: ManualSpecimenSegmentRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: ManualSpecimenSegment) -> [String] {
            let size = item.code.count
            if size > maxLength {
                return ["code is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class ManualSpecimenSegmentUpdatedAtRangeRule: ManualSpecimenSegmentRule {
        var min: Int
        var max: Int

        init(min: Int, max: Int) {
            self.min = min
            self.max = max
        }

        func check(_ item: ManualSpecimenSegment) -> [String] {
            let value = item.updatedAt
            var problems: [String] = []
            if value < min {
                problems.append("updated at \(value) is below \(min)")
            }
            if value > max {
                problems.append("updated at \(value) is above \(max)")
            }
            return problems
        }
    }

    final class ManualSpecimenSegmentRequiredReviewerRule: ManualSpecimenSegmentRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: ManualSpecimenSegment) -> [String] {
            if item.reviewer.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class ManualSpecimenSegmentCodePrefixRule: ManualSpecimenSegmentRule {
        var prefix: String

        init(prefix: String) {
            self.prefix = prefix
        }

        func check(_ item: ManualSpecimenSegment) -> [String] {
            if !item.code.uppercased().hasPrefix(prefix.uppercased()) {
                return ["code must start with \(prefix)"]
            }
            return []
        }
    }

    final class ManualSpecimenSegmentContactEmailLengthRule: ManualSpecimenSegmentRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: ManualSpecimenSegment) -> [String] {
            let size = item.contactEmail.count
            if size > maxLength {
                return ["contact email is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    /// Runs every rule of a manual specimen segment.
    final class ManualSpecimenSegmentValidator {
        var rules: [any ManualSpecimenSegmentRule]

        init(rules: [any ManualSpecimenSegmentRule]) {
            self.rules = rules
        }

        func validate(_ item: ManualSpecimenSegment) -> [String] {
            var problems: [String] = []
            for rule in rules {
                for problem in rule.check(item) {
                    problems.append(problem)
                }
            }
            return problems
        }

        func requireValid(_ item: ManualSpecimenSegment) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.label()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [ManualSpecimenSegment]) -> [String: [String]] {
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

    static func defaultManualSpecimenSegmentValidator() -> ManualSpecimenSegmentValidator {
        return ManualSpecimenSegmentValidator(
            rules: [
                ManualSpecimenSegmentCodeLengthRule(maxLength: 1000),
                ManualSpecimenSegmentUpdatedAtRangeRule(min: 1000, max: 86400),
                ManualSpecimenSegmentRequiredReviewerRule(message: "manual specimen segment needs this field"),
                ManualSpecimenSegmentCodePrefixRule(prefix: "OPS"),
                ManualSpecimenSegmentContactEmailLengthRule(maxLength: 3600),
            ]
        )
    }
}
