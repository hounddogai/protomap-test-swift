import AcmePlatform
import Foundation

extension ClinicalOps {
    /// A rule a legacy alert notice must pass. Check returns its problems, or none.
    protocol LegacyAlertNoticeRule {
        func check(_ item: LegacyAlertNotice) -> [String]
    }

    final class LegacyAlertNoticeClinicianIDLengthRule: LegacyAlertNoticeRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: LegacyAlertNotice) -> [String] {
            let size = item.clinicianID.count
            if size > maxLength {
                return ["clinician id is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class LegacyAlertNoticeNotesLengthRule: LegacyAlertNoticeRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: LegacyAlertNotice) -> [String] {
            let size = item.notes.count
            if size > maxLength {
                return ["notes is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class LegacyAlertNoticeRequiredClinicianIDRule: LegacyAlertNoticeRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: LegacyAlertNotice) -> [String] {
            if item.clinicianID.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class LegacyAlertNoticeMarginRangeRule: LegacyAlertNoticeRule {
        var min: Double
        var max: Double

        init(min: Double, max: Double) {
            self.min = min
            self.max = max
        }

        func check(_ item: LegacyAlertNotice) -> [String] {
            let value = item.margin
            if value < min || value > max {
                return ["margin \(value) is outside \(min) to \(max)"]
            }
            return []
        }
    }

    final class LegacyAlertNoticeMaximumRangeRule: LegacyAlertNoticeRule {
        var min: Double
        var max: Double

        init(min: Double, max: Double) {
            self.min = min
            self.max = max
        }

        func check(_ item: LegacyAlertNotice) -> [String] {
            let value = item.maximum
            var problems: [String] = []
            if value < min {
                problems.append("maximum \(value) is below \(min)")
            }
            if value > max {
                problems.append("maximum \(value) is above \(max)")
            }
            return problems
        }
    }

    /// Runs every rule of a legacy alert notice.
    final class LegacyAlertNoticeValidator {
        var rules: [any LegacyAlertNoticeRule]

        init(rules: [any LegacyAlertNoticeRule]) {
            self.rules = rules
        }

        func validate(_ item: LegacyAlertNotice) -> [String] {
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

        func requireValid(_ item: LegacyAlertNotice) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.label()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [LegacyAlertNotice]) -> [String: [String]] {
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

    static func defaultLegacyAlertNoticeValidator() -> LegacyAlertNoticeValidator {
        return LegacyAlertNoticeValidator(
            rules: [
                LegacyAlertNoticeClinicianIDLengthRule(maxLength: 120),
                LegacyAlertNoticeNotesLengthRule(maxLength: 3600),
                LegacyAlertNoticeRequiredClinicianIDRule(message: "legacy alert notice needs this field"),
                LegacyAlertNoticeMarginRangeRule(min: 4.8, max: 1319.2),
                LegacyAlertNoticeMaximumRangeRule(min: 0.9, max: 2857.7),
            ]
        )
    }
}
