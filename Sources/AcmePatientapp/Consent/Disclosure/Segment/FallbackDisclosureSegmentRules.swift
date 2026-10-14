import AcmePlatform
import Foundation

extension Consent {
    /// A rule a fallback disclosure segment must pass. Check returns its problems, or none.
    protocol FallbackDisclosureSegmentRule {
        func check(_ item: FallbackDisclosureSegment) -> [String]
    }

    final class FallbackDisclosureSegmentSequenceRangeRule: FallbackDisclosureSegmentRule {
        var min: Int
        var max: Int

        init(min: Int, max: Int) {
            self.min = min
            self.max = max
        }

        func check(_ item: FallbackDisclosureSegment) -> [String] {
            let value = item.sequence
            if value < min || value > max {
                return ["sequence \(value) is outside \(min) to \(max)"]
            }
            return []
        }
    }

    final class FallbackDisclosureSegmentRequiredDiagnosisCodeRule: FallbackDisclosureSegmentRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: FallbackDisclosureSegment) -> [String] {
            if item.diagnosisCode.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class FallbackDisclosureSegmentRequiredNameRule: FallbackDisclosureSegmentRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: FallbackDisclosureSegment) -> [String] {
            if item.name.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class FallbackDisclosureSegmentDiagnosisCodeLengthRule: FallbackDisclosureSegmentRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: FallbackDisclosureSegment) -> [String] {
            let size = item.diagnosisCode.count
            if size > maxLength {
                return ["diagnosis code is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class FallbackDisclosureSegmentLimitRangeRule: FallbackDisclosureSegmentRule {
        var min: Int
        var max: Int

        init(min: Int, max: Int) {
            self.min = min
            self.max = max
        }

        func check(_ item: FallbackDisclosureSegment) -> [String] {
            let value = item.limit
            if value < min || value > max {
                return ["limit \(value) is outside \(min) to \(max)"]
            }
            return []
        }
    }

    /// Runs every rule of a fallback disclosure segment.
    final class FallbackDisclosureSegmentValidator {
        var rules: [any FallbackDisclosureSegmentRule]

        init(rules: [any FallbackDisclosureSegmentRule]) {
            self.rules = rules
        }

        func validate(_ item: FallbackDisclosureSegment) -> [String] {
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

        func requireValid(_ item: FallbackDisclosureSegment) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.label()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [FallbackDisclosureSegment]) -> [String: [String]] {
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

    static func defaultFallbackDisclosureSegmentValidator() -> FallbackDisclosureSegmentValidator {
        return FallbackDisclosureSegmentValidator(
            rules: [
                FallbackDisclosureSegmentSequenceRangeRule(min: 32, max: 120),
                FallbackDisclosureSegmentRequiredDiagnosisCodeRule(
                    message: "fallback disclosure segment needs this field"
                ),
                FallbackDisclosureSegmentRequiredNameRule(message: "fallback disclosure segment needs this field"),
                FallbackDisclosureSegmentDiagnosisCodeLengthRule(maxLength: 16),
                FallbackDisclosureSegmentLimitRangeRule(min: 32, max: 255),
            ]
        )
    }
}
