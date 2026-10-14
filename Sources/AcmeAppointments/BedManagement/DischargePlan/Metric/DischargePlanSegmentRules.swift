import AcmePlatform
import Foundation

extension BedManagement {
    /// A rule a discharge plan segment must pass. Check returns its problems, or none.
    protocol DischargePlanSegmentRule {
        func check(_ item: DischargePlanSegment) -> [String]
    }

    final class DischargePlanSegmentRequiredCodeRule: DischargePlanSegmentRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: DischargePlanSegment) -> [String] {
            if item.code.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class DischargePlanSegmentRequiredNameRule: DischargePlanSegmentRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: DischargePlanSegment) -> [String] {
            if item.name.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class DischargePlanSegmentRequiredClinicianIDRule: DischargePlanSegmentRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: DischargePlanSegment) -> [String] {
            if item.clinicianID.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class DischargePlanSegmentRequiredReviewerRule: DischargePlanSegmentRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: DischargePlanSegment) -> [String] {
            if item.reviewer.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class DischargePlanSegmentAllowedCodeRule: DischargePlanSegmentRule {
        var allowed: [String]

        init(allowed: [String]) {
            self.allowed = allowed
        }

        func check(_ item: DischargePlanSegment) -> [String] {
            if allowed.count == 0 {
                return []
            }
            if !allowed.contains(Kit.Text.normalize(item.code)) {
                return ["code \(item.code) is blocked"]
            }
            return []
        }
    }

    final class DischargePlanSegmentFloorValueRangeRule: DischargePlanSegmentRule {
        var min: Double
        var max: Double

        init(min: Double, max: Double) {
            self.min = min
            self.max = max
        }

        func check(_ item: DischargePlanSegment) -> [String] {
            let value = item.floorValue
            var problems: [String] = []
            if value < min {
                problems.append("floor value \(value) is below \(min)")
            }
            if value > max {
                problems.append("floor value \(value) is above \(max)")
            }
            return problems
        }
    }

    /// Runs every rule of a discharge plan segment.
    final class DischargePlanSegmentValidator {
        var rules: [any DischargePlanSegmentRule]

        init(rules: [any DischargePlanSegmentRule]) {
            self.rules = rules
        }

        func validate(_ item: DischargePlanSegment) -> [String] {
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

        func requireValid(_ item: DischargePlanSegment) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.label()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [DischargePlanSegment]) -> [String: [String]] {
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

    static func defaultDischargePlanSegmentValidator() -> DischargePlanSegmentValidator {
        return DischargePlanSegmentValidator(
            rules: [
                DischargePlanSegmentRequiredCodeRule(message: "discharge plan segment needs an entry"),
                DischargePlanSegmentRequiredNameRule(message: "discharge plan segment needs an entry"),
                DischargePlanSegmentRequiredClinicianIDRule(message: "discharge plan segment needs an entry"),
                DischargePlanSegmentRequiredReviewerRule(message: "discharge plan segment needs a value"),
                DischargePlanSegmentAllowedCodeRule(allowed: ["tiered", "global"]),
                DischargePlanSegmentFloorValueRangeRule(min: 6.8, max: 967.6),
            ]
        )
    }
}
