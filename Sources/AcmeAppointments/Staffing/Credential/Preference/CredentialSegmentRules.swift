import AcmePlatform
import Foundation

extension Staffing {
    /// A rule a credential segment must pass. Check returns its problems, or none.
    protocol CredentialSegmentRule {
        func check(_ item: CredentialSegment) -> [String]
    }

    final class CredentialSegmentDiagnosisCodeLengthRule: CredentialSegmentRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: CredentialSegment) -> [String] {
            let size = item.diagnosisCode.count
            if size > maxLength {
                return ["diagnosis code is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class CredentialSegmentLabelLengthRule: CredentialSegmentRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: CredentialSegment) -> [String] {
            let size = item.label.count
            if size > maxLength {
                return ["label is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class CredentialSegmentAcuityRangeRule: CredentialSegmentRule {
        var min: Int
        var max: Int

        init(min: Int, max: Int) {
            self.min = min
            self.max = max
        }

        func check(_ item: CredentialSegment) -> [String] {
            let value = item.acuity
            var problems: [String] = []
            if value < min {
                problems.append("acuity \(value) is below \(min)")
            }
            if value > max {
                problems.append("acuity \(value) is above \(max)")
            }
            return problems
        }
    }

    /// Runs every rule of a credential segment.
    final class CredentialSegmentValidator {
        var rules: [any CredentialSegmentRule]

        init(rules: [any CredentialSegmentRule]) {
            self.rules = rules
        }

        func validate(_ item: CredentialSegment) -> [String] {
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

        func requireValid(_ item: CredentialSegment) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.displayLabel()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [CredentialSegment]) -> [String: [String]] {
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

    static func defaultCredentialSegmentValidator() -> CredentialSegmentValidator {
        return CredentialSegmentValidator(
            rules: [
                CredentialSegmentDiagnosisCodeLengthRule(maxLength: 120),
                CredentialSegmentLabelLengthRule(maxLength: 16),
                CredentialSegmentAcuityRangeRule(min: 1000, max: 1000),
            ]
        )
    }
}
