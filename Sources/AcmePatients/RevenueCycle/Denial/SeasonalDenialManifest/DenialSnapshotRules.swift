import AcmePlatform
import Foundation

extension RevenueCycle {
    /// A rule a denial snapshot must pass. Check returns its problems, or none.
    protocol DenialSnapshotRule {
        func check(_ item: DenialSnapshot) -> [String]
    }

    final class DenialSnapshotRequiredNameRule: DenialSnapshotRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: DenialSnapshot) -> [String] {
            if item.name.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class DenialSnapshotAttemptsRangeRule: DenialSnapshotRule {
        var min: Int
        var max: Int

        init(min: Int, max: Int) {
            self.min = min
            self.max = max
        }

        func check(_ item: DenialSnapshot) -> [String] {
            let value = item.attempts
            var problems: [String] = []
            if value < min {
                problems.append("attempts \(value) is below \(min)")
            }
            if value > max {
                problems.append("attempts \(value) is above \(max)")
            }
            return problems
        }
    }

    final class DenialSnapshotRequiredCodeRule: DenialSnapshotRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: DenialSnapshot) -> [String] {
            if item.code.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class DenialSnapshotCodeLengthRule: DenialSnapshotRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: DenialSnapshot) -> [String] {
            let size = item.code.count
            if size > maxLength {
                return ["code is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    /// Runs every rule of a denial snapshot.
    final class DenialSnapshotValidator {
        var rules: [any DenialSnapshotRule]

        init(rules: [any DenialSnapshotRule]) {
            self.rules = rules
        }

        func validate(_ item: DenialSnapshot) -> [String] {
            var problems: [String] = []
            for rule in rules {
                for problem in rule.check(item) {
                    problems.append(problem)
                }
            }
            return problems
        }

        func requireValid(_ item: DenialSnapshot) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.label()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [DenialSnapshot]) -> [String: [String]] {
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

    static func defaultDenialSnapshotValidator() -> DenialSnapshotValidator {
        return DenialSnapshotValidator(
            rules: [
                DenialSnapshotRequiredNameRule(message: "denial snapshot needs an entry"),
                DenialSnapshotAttemptsRangeRule(min: 80, max: 120),
                DenialSnapshotRequiredCodeRule(message: "denial snapshot needs a value"),
                DenialSnapshotCodeLengthRule(maxLength: 16),
            ]
        )
    }
}
