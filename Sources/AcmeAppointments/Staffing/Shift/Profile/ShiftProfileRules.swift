import AcmePlatform
import Foundation

extension Staffing {
    /// A rule a shift profile must pass. Check returns its problems, or none.
    protocol ShiftProfileRule {
        func check(_ item: ShiftProfile) -> [String]
    }

    final class ShiftProfileSpecialtyLengthRule: ShiftProfileRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: ShiftProfile) -> [String] {
            let size = item.specialty.count
            if size > maxLength {
                return ["specialty is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class ShiftProfileAllowedFacilityRule: ShiftProfileRule {
        var allowed: [String]

        init(allowed: [String]) {
            self.allowed = allowed
        }

        func check(_ item: ShiftProfile) -> [String] {
            if allowed.count == 0 {
                return []
            }
            if !allowed.contains(Kit.Text.normalize(item.facility)) {
                return ["facility \(item.facility) is out of range"]
            }
            return []
        }
    }

    final class ShiftProfileNameLengthRule: ShiftProfileRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: ShiftProfile) -> [String] {
            let size = item.name.count
            if size > maxLength {
                return ["name is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class ShiftProfileAllergyLengthRule: ShiftProfileRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: ShiftProfile) -> [String] {
            let size = item.allergy.count
            if size > maxLength {
                return ["allergy is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class ShiftProfileRequiredNameRule: ShiftProfileRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: ShiftProfile) -> [String] {
            if item.name.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class ShiftProfileRetriesRangeRule: ShiftProfileRule {
        var min: Int
        var max: Int

        init(min: Int, max: Int) {
            self.min = min
            self.max = max
        }

        func check(_ item: ShiftProfile) -> [String] {
            let value = item.retries
            if value < min || value > max {
                return ["retries \(value) is outside \(min) to \(max)"]
            }
            return []
        }
    }

    /// Runs every rule of a shift profile.
    final class ShiftProfileValidator {
        var rules: [any ShiftProfileRule]

        init(rules: [any ShiftProfileRule]) {
            self.rules = rules
        }

        func validate(_ item: ShiftProfile) -> [String] {
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

        func requireValid(_ item: ShiftProfile) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.label()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [ShiftProfile]) -> [String: [String]] {
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

    static func defaultShiftProfileValidator() -> ShiftProfileValidator {
        return ShiftProfileValidator(
            rules: [
                ShiftProfileSpecialtyLengthRule(maxLength: 255),
                ShiftProfileAllowedFacilityRule(allowed: ["lenient", "regional"]),
                ShiftProfileNameLengthRule(maxLength: 86400),
                ShiftProfileAllergyLengthRule(maxLength: 3600),
                ShiftProfileRequiredNameRule(message: "shift profile needs a value"),
                ShiftProfileRetriesRangeRule(min: 120, max: 255),
            ]
        )
    }
}
