import AcmePlatform
import Foundation

extension Imaging {
    /// A rule a rolling study segment must pass. Check returns its problems, or none.
    protocol RollingStudySegmentRule {
        func check(_ item: RollingStudySegment) -> [String]
    }

    final class RollingStudySegmentCodePrefixRule: RollingStudySegmentRule {
        var prefix: String

        init(prefix: String) {
            self.prefix = prefix
        }

        func check(_ item: RollingStudySegment) -> [String] {
            if !item.code.uppercased().hasPrefix(prefix.uppercased()) {
                return ["code must start with \(prefix)"]
            }
            return []
        }
    }

    final class RollingStudySegmentRequiredPatientRefRule: RollingStudySegmentRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: RollingStudySegment) -> [String] {
            if item.patientRef.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class RollingStudySegmentPayerLengthRule: RollingStudySegmentRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: RollingStudySegment) -> [String] {
            let size = item.payer.count
            if size > maxLength {
                return ["payer is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    /// Runs every rule of a rolling study segment.
    final class RollingStudySegmentValidator {
        var rules: [any RollingStudySegmentRule]

        init(rules: [any RollingStudySegmentRule]) {
            self.rules = rules
        }

        func validate(_ item: RollingStudySegment) -> [String] {
            var problems: [String] = []
            for rule in rules {
                for problem in rule.check(item) {
                    problems.append(problem)
                }
            }
            return problems
        }

        func requireValid(_ item: RollingStudySegment) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.displayLabel()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [RollingStudySegment]) -> [String: [String]] {
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

    static func defaultRollingStudySegmentValidator() -> RollingStudySegmentValidator {
        return RollingStudySegmentValidator(
            rules: [
                RollingStudySegmentCodePrefixRule(prefix: "OPS"),
                RollingStudySegmentRequiredPatientRefRule(message: "rolling study segment needs this field"),
                RollingStudySegmentPayerLengthRule(maxLength: 3600),
            ]
        )
    }
}
