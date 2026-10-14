import AcmePlatform
import Foundation

extension Staffing {
    /// A rule a acuity plan notice must pass. Check returns its problems, or none.
    protocol AcuityPlanNoticeRule {
        func check(_ item: AcuityPlanNotice) -> [String]
    }

    final class AcuityPlanNoticeWeightRangeRule: AcuityPlanNoticeRule {
        var min: Double
        var max: Double

        init(min: Double, max: Double) {
            self.min = min
            self.max = max
        }

        func check(_ item: AcuityPlanNotice) -> [String] {
            let value = item.weight
            if value < min || value > max {
                return ["weight \(value) is outside \(min) to \(max)"]
            }
            return []
        }
    }

    final class AcuityPlanNoticeLabelLengthRule: AcuityPlanNoticeRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: AcuityPlanNotice) -> [String] {
            let size = item.label.count
            if size > maxLength {
                return ["label is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class AcuityPlanNoticeClinicianIDLengthRule: AcuityPlanNoticeRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: AcuityPlanNotice) -> [String] {
            let size = item.clinicianID.count
            if size > maxLength {
                return ["clinician id is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class AcuityPlanNoticeRequiredLabelRule: AcuityPlanNoticeRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: AcuityPlanNotice) -> [String] {
            if item.label.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class AcuityPlanNoticeWindowRule: AcuityPlanNoticeRule {
        var maxSpan: Int

        init(maxSpan: Int) {
            self.maxSpan = maxSpan
        }

        func check(_ item: AcuityPlanNotice) -> [String] {
            if item.startsAt > item.endsAt {
                return ["starts at is after ends at"]
            }
            if maxSpan > 0 && (item.endsAt - item.startsAt > maxSpan) {
                return ["spans more than \(maxSpan) seconds"]
            }
            return []
        }
    }

    final class AcuityPlanNoticeEndsAtRangeRule: AcuityPlanNoticeRule {
        var min: Int
        var max: Int

        init(min: Int, max: Int) {
            self.min = min
            self.max = max
        }

        func check(_ item: AcuityPlanNotice) -> [String] {
            let value = item.endsAt
            if value < min || value > max {
                return ["ends at \(value) is outside \(min) to \(max)"]
            }
            return []
        }
    }

    /// Runs every rule of a acuity plan notice.
    final class AcuityPlanNoticeValidator {
        var rules: [any AcuityPlanNoticeRule]

        init(rules: [any AcuityPlanNoticeRule]) {
            self.rules = rules
        }

        func validate(_ item: AcuityPlanNotice) -> [String] {
            var problems: [String] = []
            for rule in rules {
                for problem in rule.check(item) {
                    problems.append(problem)
                }
            }
            return problems
        }

        func requireValid(_ item: AcuityPlanNotice) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.displayLabel()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [AcuityPlanNotice]) -> [String: [String]] {
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

    static func defaultAcuityPlanNoticeValidator() -> AcuityPlanNoticeValidator {
        return AcuityPlanNoticeValidator(
            rules: [
                AcuityPlanNoticeWeightRangeRule(min: 8.0, max: 4514.5),
                AcuityPlanNoticeLabelLengthRule(maxLength: 16),
                AcuityPlanNoticeClinicianIDLengthRule(maxLength: 80),
                AcuityPlanNoticeRequiredLabelRule(message: "acuity plan notice needs this field"),
                AcuityPlanNoticeWindowRule(maxSpan: 255),
                AcuityPlanNoticeEndsAtRangeRule(min: 3600, max: 86400),
            ]
        )
    }
}
