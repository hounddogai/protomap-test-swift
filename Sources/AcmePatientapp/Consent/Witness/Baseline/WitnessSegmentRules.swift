import AcmePlatform
import Foundation

extension Consent {
    /// A rule a witness segment must pass. Check returns its problems, or none.
    protocol WitnessSegmentRule {
        func check(_ item: WitnessSegment) -> [String]
    }

    final class WitnessSegmentCodeLengthRule: WitnessSegmentRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: WitnessSegment) -> [String] {
            let size = item.code.count
            if size > maxLength {
                return ["code is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class WitnessSegmentClinicianIDLengthRule: WitnessSegmentRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: WitnessSegment) -> [String] {
            let size = item.clinicianID.count
            if size > maxLength {
                return ["clinician id is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class WitnessSegmentDurationMinutesRangeRule: WitnessSegmentRule {
        var min: Int
        var max: Int

        init(min: Int, max: Int) {
            self.min = min
            self.max = max
        }

        func check(_ item: WitnessSegment) -> [String] {
            let value = item.durationMinutes
            var problems: [String] = []
            if value < min {
                problems.append("duration minutes \(value) is below \(min)")
            }
            if value > max {
                problems.append("duration minutes \(value) is above \(max)")
            }
            return problems
        }
    }

    /// Runs every rule of a witness segment.
    final class WitnessSegmentValidator {
        var rules: [any WitnessSegmentRule]

        init(rules: [any WitnessSegmentRule]) {
            self.rules = rules
        }

        func validate(_ item: WitnessSegment) -> [String] {
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

        func requireValid(_ item: WitnessSegment) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.displayLabel()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [WitnessSegment]) -> [String: [String]] {
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

    static func defaultWitnessSegmentValidator() -> WitnessSegmentValidator {
        return WitnessSegmentValidator(
            rules: [
                WitnessSegmentCodeLengthRule(maxLength: 16),
                WitnessSegmentClinicianIDLengthRule(maxLength: 120),
                WitnessSegmentDurationMinutesRangeRule(min: 120, max: 86400),
            ]
        )
    }
}
