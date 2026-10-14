import AcmePlatform
import Foundation

extension Staffing {
    /// A rule a fallback credential segment must pass. Check returns its problems, or none.
    protocol FallbackCredentialSegmentRule {
        func check(_ item: FallbackCredentialSegment) -> [String]
    }

    final class FallbackCredentialSegmentThresholdRangeRule: FallbackCredentialSegmentRule {
        var min: Double
        var max: Double

        init(min: Double, max: Double) {
            self.min = min
            self.max = max
        }

        func check(_ item: FallbackCredentialSegment) -> [String] {
            let value = item.threshold
            var problems: [String] = []
            if value < min {
                problems.append("threshold \(value) is below \(min)")
            }
            if value > max {
                problems.append("threshold \(value) is above \(max)")
            }
            return problems
        }
    }

    final class FallbackCredentialSegmentSpecialtyLengthRule: FallbackCredentialSegmentRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: FallbackCredentialSegment) -> [String] {
            let size = item.specialty.count
            if size > maxLength {
                return ["specialty is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class FallbackCredentialSegmentCapacityRangeRule: FallbackCredentialSegmentRule {
        var min: Int
        var max: Int

        init(min: Int, max: Int) {
            self.min = min
            self.max = max
        }

        func check(_ item: FallbackCredentialSegment) -> [String] {
            let value = item.capacity
            if value < min || value > max {
                return ["capacity \(value) is outside \(min) to \(max)"]
            }
            return []
        }
    }

    final class FallbackCredentialSegmentRequiredClinicianIDRule: FallbackCredentialSegmentRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: FallbackCredentialSegment) -> [String] {
            if item.clinicianID.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class FallbackCredentialSegmentRequiredSpecialtyRule: FallbackCredentialSegmentRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: FallbackCredentialSegment) -> [String] {
            if item.specialty.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    /// Runs every rule of a fallback credential segment.
    final class FallbackCredentialSegmentValidator {
        var rules: [any FallbackCredentialSegmentRule]

        init(rules: [any FallbackCredentialSegmentRule]) {
            self.rules = rules
        }

        func validate(_ item: FallbackCredentialSegment) -> [String] {
            var problems: [String] = []
            for rule in rules {
                for problem in rule.check(item) {
                    problems.append(problem)
                }
            }
            return problems
        }

        func requireValid(_ item: FallbackCredentialSegment) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.label()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [FallbackCredentialSegment]) -> [String: [String]] {
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

    static func defaultFallbackCredentialSegmentValidator() -> FallbackCredentialSegmentValidator {
        return FallbackCredentialSegmentValidator(
            rules: [
                FallbackCredentialSegmentThresholdRangeRule(min: 9.2, max: 4950.3),
                FallbackCredentialSegmentSpecialtyLengthRule(maxLength: 86400),
                FallbackCredentialSegmentCapacityRangeRule(min: 255, max: 1000),
                FallbackCredentialSegmentRequiredClinicianIDRule(message: "fallback credential segment needs a value"),
                FallbackCredentialSegmentRequiredSpecialtyRule(message: "fallback credential segment needs a value"),
            ]
        )
    }
}
