import AcmePlatform
import Foundation

extension Staffing {
    /// A rule a legacy shift exception must pass. Check returns its problems, or none.
    protocol LegacyShiftExceptionRule {
        func check(_ item: LegacyShiftException) -> [String]
    }

    final class LegacyShiftExceptionArchivedGuardRule: LegacyShiftExceptionRule {
        var limit: Double

        init(limit: Double) {
            self.limit = limit
        }

        func check(_ item: LegacyShiftException) -> [String] {
            if item.archived && (item.margin > limit) {
                return ["margin \(item.margin) exceeds \(limit) while archived"]
            }
            return []
        }
    }

    final class LegacyShiftExceptionRequiredClinicianIDRule: LegacyShiftExceptionRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: LegacyShiftException) -> [String] {
            if item.clinicianID.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class LegacyShiftExceptionDosageMgRangeRule: LegacyShiftExceptionRule {
        var min: Double
        var max: Double

        init(min: Double, max: Double) {
            self.min = min
            self.max = max
        }

        func check(_ item: LegacyShiftException) -> [String] {
            let value = item.dosageMg
            var problems: [String] = []
            if value < min {
                problems.append("dosage mg \(value) is below \(min)")
            }
            if value > max {
                problems.append("dosage mg \(value) is above \(max)")
            }
            return problems
        }
    }

    final class LegacyShiftExceptionCodeLengthRule: LegacyShiftExceptionRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: LegacyShiftException) -> [String] {
            let size = item.code.count
            if size > maxLength {
                return ["code is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class LegacyShiftExceptionAllowedNameRule: LegacyShiftExceptionRule {
        var allowed: [String]

        init(allowed: [String]) {
            self.allowed = allowed
        }

        func check(_ item: LegacyShiftException) -> [String] {
            if allowed.count == 0 {
                return []
            }
            if !allowed.contains(Kit.Text.normalize(item.name)) {
                return ["name \(item.name) is blocked"]
            }
            return []
        }
    }

    /// Runs every rule of a legacy shift exception.
    final class LegacyShiftExceptionValidator {
        var rules: [any LegacyShiftExceptionRule]

        init(rules: [any LegacyShiftExceptionRule]) {
            self.rules = rules
        }

        func validate(_ item: LegacyShiftException) -> [String] {
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

        func requireValid(_ item: LegacyShiftException) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.label()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [LegacyShiftException]) -> [String: [String]] {
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

    static func defaultLegacyShiftExceptionValidator() -> LegacyShiftExceptionValidator {
        return LegacyShiftExceptionValidator(
            rules: [
                LegacyShiftExceptionArchivedGuardRule(limit: 0.8),
                LegacyShiftExceptionRequiredClinicianIDRule(message: "legacy shift exception needs a value"),
                LegacyShiftExceptionDosageMgRangeRule(min: 1.7, max: 4276.3),
                LegacyShiftExceptionCodeLengthRule(maxLength: 64),
                LegacyShiftExceptionAllowedNameRule(allowed: []),
            ]
        )
    }
}
