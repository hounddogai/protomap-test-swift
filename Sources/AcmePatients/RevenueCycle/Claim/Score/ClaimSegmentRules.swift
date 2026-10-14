import AcmePlatform
import Foundation

extension RevenueCycle {
    /// A rule a claim segment must pass. Check returns its problems, or none.
    protocol ClaimSegmentRule {
        func check(_ item: ClaimSegment) -> [String]
    }

    final class ClaimSegmentPatientRefLengthRule: ClaimSegmentRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: ClaimSegment) -> [String] {
            let size = item.patientRef.count
            if size > maxLength {
                return ["patient ref is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class ClaimSegmentCeilingRangeRule: ClaimSegmentRule {
        var min: Double
        var max: Double

        init(min: Double, max: Double) {
            self.min = min
            self.max = max
        }

        func check(_ item: ClaimSegment) -> [String] {
            let value = item.ceiling
            var problems: [String] = []
            if value < min {
                problems.append("ceiling \(value) is below \(min)")
            }
            if value > max {
                problems.append("ceiling \(value) is above \(max)")
            }
            return problems
        }
    }

    final class ClaimSegmentCodeLengthRule: ClaimSegmentRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: ClaimSegment) -> [String] {
            let size = item.code.count
            if size > maxLength {
                return ["code is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    /// Runs every rule of a claim segment.
    final class ClaimSegmentValidator {
        var rules: [any ClaimSegmentRule]

        init(rules: [any ClaimSegmentRule]) {
            self.rules = rules
        }

        func validate(_ item: ClaimSegment) -> [String] {
            var problems: [String] = []
            for rule in rules {
                for problem in rule.check(item) {
                    problems.append(problem)
                }
            }
            return problems
        }

        func requireValid(_ item: ClaimSegment) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.displayLabel()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [ClaimSegment]) -> [String: [String]] {
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

    static func defaultClaimSegmentValidator() -> ClaimSegmentValidator {
        return ClaimSegmentValidator(
            rules: [
                ClaimSegmentPatientRefLengthRule(maxLength: 120),
                ClaimSegmentCeilingRangeRule(min: 3.8, max: 3570.1),
                ClaimSegmentCodeLengthRule(maxLength: 255),
            ]
        )
    }
}
