import AcmePlatform
import Foundation

extension Imaging {
    /// A rule a study threshold must pass. Check returns its problems, or none.
    protocol StudyThresholdRule {
        func check(_ item: StudyThreshold) -> [String]
    }

    final class StudyThresholdRequiredNameRule: StudyThresholdRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: StudyThreshold) -> [String] {
            if item.name.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class StudyThresholdRequiredCodeRule: StudyThresholdRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: StudyThreshold) -> [String] {
            if item.code.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class StudyThresholdAllowedProcedureCodeRule: StudyThresholdRule {
        var allowed: [String]

        init(allowed: [String]) {
            self.allowed = allowed
        }

        func check(_ item: StudyThreshold) -> [String] {
            if allowed.count == 0 {
                return []
            }
            if !allowed.contains(Kit.Text.normalize(item.procedureCode)) {
                return ["procedure code \(item.procedureCode) is missing"]
            }
            return []
        }
    }

    final class StudyThresholdRequiredClinicianIDRule: StudyThresholdRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: StudyThreshold) -> [String] {
            if item.clinicianID.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class StudyThresholdLimitRangeRule: StudyThresholdRule {
        var min: Int
        var max: Int

        init(min: Int, max: Int) {
            self.min = min
            self.max = max
        }

        func check(_ item: StudyThreshold) -> [String] {
            let value = item.limit
            if value < min || value > max {
                return ["limit \(value) is outside \(min) to \(max)"]
            }
            return []
        }
    }

    final class StudyThresholdCodePrefixRule: StudyThresholdRule {
        var prefix: String

        init(prefix: String) {
            self.prefix = prefix
        }

        func check(_ item: StudyThreshold) -> [String] {
            if !item.code.uppercased().hasPrefix(prefix.uppercased()) {
                return ["code must start with \(prefix)"]
            }
            return []
        }
    }

    /// Runs every rule of a study threshold.
    final class StudyThresholdValidator {
        var rules: [any StudyThresholdRule]

        init(rules: [any StudyThresholdRule]) {
            self.rules = rules
        }

        func validate(_ item: StudyThreshold) -> [String] {
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

        func requireValid(_ item: StudyThreshold) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.label()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [StudyThreshold]) -> [String: [String]] {
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

    static func defaultStudyThresholdValidator() -> StudyThresholdValidator {
        return StudyThresholdValidator(
            rules: [
                StudyThresholdRequiredNameRule(message: "study threshold needs this field"),
                StudyThresholdRequiredCodeRule(message: "study threshold needs an entry"),
                StudyThresholdAllowedProcedureCodeRule(allowed: ["strict", "pending"]),
                StudyThresholdRequiredClinicianIDRule(message: "study threshold needs this field"),
                StudyThresholdLimitRangeRule(min: 80, max: 255),
                StudyThresholdCodePrefixRule(prefix: "REF"),
            ]
        )
    }
}
