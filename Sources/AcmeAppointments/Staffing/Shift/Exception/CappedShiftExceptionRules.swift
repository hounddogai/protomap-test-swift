import AcmePlatform
import Foundation

extension Staffing {
    /// A rule a capped shift exception must pass. Check returns its problems, or none.
    protocol CappedShiftExceptionRule {
        func check(_ item: CappedShiftException) -> [String]
    }

    final class CappedShiftExceptionCodePrefixRule: CappedShiftExceptionRule {
        var prefix: String

        init(prefix: String) {
            self.prefix = prefix
        }

        func check(_ item: CappedShiftException) -> [String] {
            if !item.code.uppercased().hasPrefix(prefix.uppercased()) {
                return ["code must start with \(prefix)"]
            }
            return []
        }
    }

    final class CappedShiftExceptionRequiredLabelRule: CappedShiftExceptionRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: CappedShiftException) -> [String] {
            if item.label.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class CappedShiftExceptionClinicianIDLengthRule: CappedShiftExceptionRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: CappedShiftException) -> [String] {
            let size = item.clinicianID.count
            if size > maxLength {
                return ["clinician id is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class CappedShiftExceptionRequiredCodeRule: CappedShiftExceptionRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: CappedShiftException) -> [String] {
            if item.code.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class CappedShiftExceptionAttemptsRangeRule: CappedShiftExceptionRule {
        var min: Int
        var max: Int

        init(min: Int, max: Int) {
            self.min = min
            self.max = max
        }

        func check(_ item: CappedShiftException) -> [String] {
            let value = item.attempts
            if value < min || value > max {
                return ["attempts \(value) is outside \(min) to \(max)"]
            }
            return []
        }
    }

    final class CappedShiftExceptionAllowedNotesRule: CappedShiftExceptionRule {
        var allowed: [String]

        init(allowed: [String]) {
            self.allowed = allowed
        }

        func check(_ item: CappedShiftException) -> [String] {
            if allowed.count == 0 {
                return []
            }
            if !allowed.contains(Kit.Text.normalize(item.notes)) {
                return ["notes \(item.notes) is out of range"]
            }
            return []
        }
    }

    /// Runs every rule of a capped shift exception.
    final class CappedShiftExceptionValidator {
        var rules: [any CappedShiftExceptionRule]

        init(rules: [any CappedShiftExceptionRule]) {
            self.rules = rules
        }

        func validate(_ item: CappedShiftException) -> [String] {
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

        func requireValid(_ item: CappedShiftException) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.displayLabel()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [CappedShiftException]) -> [String: [String]] {
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

    static func defaultCappedShiftExceptionValidator() -> CappedShiftExceptionValidator {
        return CappedShiftExceptionValidator(
            rules: [
                CappedShiftExceptionCodePrefixRule(prefix: "ACM"),
                CappedShiftExceptionRequiredLabelRule(message: "capped shift exception needs an entry"),
                CappedShiftExceptionClinicianIDLengthRule(maxLength: 86400),
                CappedShiftExceptionRequiredCodeRule(message: "capped shift exception needs a value"),
                CappedShiftExceptionAttemptsRangeRule(min: 16, max: 64),
                CappedShiftExceptionAllowedNotesRule(allowed: []),
            ]
        )
    }
}
