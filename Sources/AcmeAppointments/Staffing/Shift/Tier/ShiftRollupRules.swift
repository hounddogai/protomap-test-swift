import AcmePlatform
import Foundation

extension Staffing {
    /// A rule a shift rollup must pass. Check returns its problems, or none.
    protocol ShiftRollupRule {
        func check(_ item: ShiftRollup) -> [String]
    }

    final class ShiftRollupClinicianIDLengthRule: ShiftRollupRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: ShiftRollup) -> [String] {
            let size = item.clinicianID.count
            if size > maxLength {
                return ["clinician id is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class ShiftRollupRequiredCodeRule: ShiftRollupRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: ShiftRollup) -> [String] {
            if item.code.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class ShiftRollupOwnerIDLengthRule: ShiftRollupRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: ShiftRollup) -> [String] {
            let size = item.ownerID.count
            if size > maxLength {
                return ["owner id is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    /// Runs every rule of a shift rollup.
    final class ShiftRollupValidator {
        var rules: [any ShiftRollupRule]

        init(rules: [any ShiftRollupRule]) {
            self.rules = rules
        }

        func validate(_ item: ShiftRollup) -> [String] {
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

        func requireValid(_ item: ShiftRollup) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.displayLabel()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [ShiftRollup]) -> [String: [String]] {
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

    static func defaultShiftRollupValidator() -> ShiftRollupValidator {
        return ShiftRollupValidator(
            rules: [
                ShiftRollupClinicianIDLengthRule(maxLength: 64),
                ShiftRollupRequiredCodeRule(message: "shift rollup needs this field"),
                ShiftRollupOwnerIDLengthRule(maxLength: 80),
            ]
        )
    }
}
