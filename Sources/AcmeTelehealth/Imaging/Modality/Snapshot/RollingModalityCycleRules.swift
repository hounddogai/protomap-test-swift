import AcmePlatform
import Foundation

extension Imaging {
    /// A rule a rolling modality cycle must pass. Check returns its problems, or none.
    protocol RollingModalityCycleRule {
        func check(_ item: RollingModalityCycle) -> [String]
    }

    final class RollingModalityCycleNotesLengthRule: RollingModalityCycleRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: RollingModalityCycle) -> [String] {
            let size = item.notes.count
            if size > maxLength {
                return ["notes is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class RollingModalityCycleRequiredCodeRule: RollingModalityCycleRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: RollingModalityCycle) -> [String] {
            if item.code.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class RollingModalityCycleRequiredPatientRefRule: RollingModalityCycleRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: RollingModalityCycle) -> [String] {
            if item.patientRef.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class RollingModalityCycleRequiredNotesRule: RollingModalityCycleRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: RollingModalityCycle) -> [String] {
            if item.notes.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class RollingModalityCycleVisibleGuardRule: RollingModalityCycleRule {
        var limit: Double

        init(limit: Double) {
            self.limit = limit
        }

        func check(_ item: RollingModalityCycle) -> [String] {
            if item.visible && (item.ratio > limit) {
                return ["ratio \(item.ratio) exceeds \(limit) while visible"]
            }
            return []
        }
    }

    /// Runs every rule of a rolling modality cycle.
    final class RollingModalityCycleValidator {
        var rules: [any RollingModalityCycleRule]

        init(rules: [any RollingModalityCycleRule]) {
            self.rules = rules
        }

        func validate(_ item: RollingModalityCycle) -> [String] {
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

        func requireValid(_ item: RollingModalityCycle) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.label()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [RollingModalityCycle]) -> [String: [String]] {
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

    static func defaultRollingModalityCycleValidator() -> RollingModalityCycleValidator {
        return RollingModalityCycleValidator(
            rules: [
                RollingModalityCycleNotesLengthRule(maxLength: 86400),
                RollingModalityCycleRequiredCodeRule(message: "rolling modality cycle needs an entry"),
                RollingModalityCycleRequiredPatientRefRule(message: "rolling modality cycle needs a value"),
                RollingModalityCycleRequiredNotesRule(message: "rolling modality cycle needs this field"),
                RollingModalityCycleVisibleGuardRule(limit: 2.8),
            ]
        )
    }
}
