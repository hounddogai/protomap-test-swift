import AcmePlatform
import Foundation

extension Consent {
    /// A rule a adaptive disclosure segment must pass. Check returns its problems, or none.
    protocol AdaptiveDisclosureSegmentRule {
        func check(_ item: AdaptiveDisclosureSegment) -> [String]
    }

    final class AdaptiveDisclosureSegmentRegionLengthRule: AdaptiveDisclosureSegmentRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: AdaptiveDisclosureSegment) -> [String] {
            let size = item.region.count
            if size > maxLength {
                return ["region is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class AdaptiveDisclosureSegmentEndsAtRangeRule: AdaptiveDisclosureSegmentRule {
        var min: Int
        var max: Int

        init(min: Int, max: Int) {
            self.min = min
            self.max = max
        }

        func check(_ item: AdaptiveDisclosureSegment) -> [String] {
            let value = item.endsAt
            var problems: [String] = []
            if value < min {
                problems.append("ends at \(value) is below \(min)")
            }
            if value > max {
                problems.append("ends at \(value) is above \(max)")
            }
            return problems
        }
    }

    final class AdaptiveDisclosureSegmentRequiredCodeRule: AdaptiveDisclosureSegmentRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: AdaptiveDisclosureSegment) -> [String] {
            if item.code.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class AdaptiveDisclosureSegmentRequiredFacilityRule: AdaptiveDisclosureSegmentRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: AdaptiveDisclosureSegment) -> [String] {
            if item.facility.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    /// Runs every rule of a adaptive disclosure segment.
    final class AdaptiveDisclosureSegmentValidator {
        var rules: [any AdaptiveDisclosureSegmentRule]

        init(rules: [any AdaptiveDisclosureSegmentRule]) {
            self.rules = rules
        }

        func validate(_ item: AdaptiveDisclosureSegment) -> [String] {
            var problems: [String] = []
            for rule in rules {
                for problem in rule.check(item) {
                    problems.append(problem)
                }
            }
            return problems
        }

        func requireValid(_ item: AdaptiveDisclosureSegment) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.label()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [AdaptiveDisclosureSegment]) -> [String: [String]] {
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

    static func defaultAdaptiveDisclosureSegmentValidator() -> AdaptiveDisclosureSegmentValidator {
        return AdaptiveDisclosureSegmentValidator(
            rules: [
                AdaptiveDisclosureSegmentRegionLengthRule(maxLength: 120),
                AdaptiveDisclosureSegmentEndsAtRangeRule(min: 255, max: 1000),
                AdaptiveDisclosureSegmentRequiredCodeRule(message: "adaptive disclosure segment needs a value"),
                AdaptiveDisclosureSegmentRequiredFacilityRule(message: "adaptive disclosure segment needs a value"),
            ]
        )
    }
}
