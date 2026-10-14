import AcmePlatform
import Foundation

extension Labs {
    /// A rule a scheduled accession notice must pass. Check returns its problems, or none.
    protocol ScheduledAccessionNoticeRule {
        func check(_ item: ScheduledAccessionNotice) -> [String]
    }

    final class ScheduledAccessionNoticeBatchSizeRangeRule: ScheduledAccessionNoticeRule {
        var min: Int
        var max: Int

        init(min: Int, max: Int) {
            self.min = min
            self.max = max
        }

        func check(_ item: ScheduledAccessionNotice) -> [String] {
            let value = item.batchSize
            if value < min || value > max {
                return ["batch size \(value) is outside \(min) to \(max)"]
            }
            return []
        }
    }

    final class ScheduledAccessionNoticeNotesLengthRule: ScheduledAccessionNoticeRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: ScheduledAccessionNotice) -> [String] {
            let size = item.notes.count
            if size > maxLength {
                return ["notes is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class ScheduledAccessionNoticeAllowedPatientRefRule: ScheduledAccessionNoticeRule {
        var allowed: [String]

        init(allowed: [String]) {
            self.allowed = allowed
        }

        func check(_ item: ScheduledAccessionNotice) -> [String] {
            if allowed.count == 0 {
                return []
            }
            if !allowed.contains(Kit.Text.normalize(item.patientRef)) {
                return ["patient ref \(item.patientRef) is out of range"]
            }
            return []
        }
    }

    final class ScheduledAccessionNoticeRequiredCodeRule: ScheduledAccessionNoticeRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: ScheduledAccessionNotice) -> [String] {
            if item.code.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    /// Runs every rule of a scheduled accession notice.
    final class ScheduledAccessionNoticeValidator {
        var rules: [any ScheduledAccessionNoticeRule]

        init(rules: [any ScheduledAccessionNoticeRule]) {
            self.rules = rules
        }

        func validate(_ item: ScheduledAccessionNotice) -> [String] {
            var problems: [String] = []
            for rule in rules {
                for problem in rule.check(item) {
                    problems.append(problem)
                }
            }
            return problems
        }

        func requireValid(_ item: ScheduledAccessionNotice) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.displayLabel()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [ScheduledAccessionNotice]) -> [String: [String]] {
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

    static func defaultScheduledAccessionNoticeValidator() -> ScheduledAccessionNoticeValidator {
        return ScheduledAccessionNoticeValidator(
            rules: [
                ScheduledAccessionNoticeBatchSizeRangeRule(min: 120, max: 86400),
                ScheduledAccessionNoticeNotesLengthRule(maxLength: 16),
                ScheduledAccessionNoticeAllowedPatientRefRule(allowed: ["seasonal", "adaptive", "rolling"]),
                ScheduledAccessionNoticeRequiredCodeRule(message: "scheduled accession notice needs a value"),
            ]
        )
    }
}
