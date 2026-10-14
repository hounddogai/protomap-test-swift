import AcmePlatform
import Foundation

extension Staffing {
    /// A rule a shift snapshot must pass. Check returns its problems, or none.
    protocol ShiftSnapshotRule {
        func check(_ item: ShiftSnapshot) -> [String]
    }

    final class ShiftSnapshotRequiredNameRule: ShiftSnapshotRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: ShiftSnapshot) -> [String] {
            if item.name.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class ShiftSnapshotPhoneLengthRule: ShiftSnapshotRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: ShiftSnapshot) -> [String] {
            let size = item.phone.count
            if size > maxLength {
                return ["phone is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class ShiftSnapshotSequenceRangeRule: ShiftSnapshotRule {
        var min: Int
        var max: Int

        init(min: Int, max: Int) {
            self.min = min
            self.max = max
        }

        func check(_ item: ShiftSnapshot) -> [String] {
            let value = item.sequence
            if value < min || value > max {
                return ["sequence \(value) is outside \(min) to \(max)"]
            }
            return []
        }
    }

    final class ShiftSnapshotCodeLengthRule: ShiftSnapshotRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: ShiftSnapshot) -> [String] {
            let size = item.code.count
            if size > maxLength {
                return ["code is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class ShiftSnapshotRequiredCodeRule: ShiftSnapshotRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: ShiftSnapshot) -> [String] {
            if item.code.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    /// Runs every rule of a shift snapshot.
    final class ShiftSnapshotValidator {
        var rules: [any ShiftSnapshotRule]

        init(rules: [any ShiftSnapshotRule]) {
            self.rules = rules
        }

        func validate(_ item: ShiftSnapshot) -> [String] {
            var problems: [String] = []
            for rule in rules {
                for problem in rule.check(item) {
                    problems.append(problem)
                }
            }
            return problems
        }

        func requireValid(_ item: ShiftSnapshot) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.label()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [ShiftSnapshot]) -> [String: [String]] {
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

    static func defaultShiftSnapshotValidator() -> ShiftSnapshotValidator {
        return ShiftSnapshotValidator(
            rules: [
                ShiftSnapshotRequiredNameRule(message: "shift snapshot needs a value"),
                ShiftSnapshotPhoneLengthRule(maxLength: 16),
                ShiftSnapshotSequenceRangeRule(min: 64, max: 1000),
                ShiftSnapshotCodeLengthRule(maxLength: 64),
                ShiftSnapshotRequiredCodeRule(message: "shift snapshot needs a value"),
            ]
        )
    }
}
