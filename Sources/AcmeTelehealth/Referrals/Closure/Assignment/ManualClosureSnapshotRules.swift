import AcmePlatform
import Foundation

extension Referrals {
    /// A rule a manual closure snapshot must pass. Check returns its problems, or none.
    protocol ManualClosureSnapshotRule {
        func check(_ item: ManualClosureSnapshot) -> [String]
    }

    final class ManualClosureSnapshotLabelLengthRule: ManualClosureSnapshotRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: ManualClosureSnapshot) -> [String] {
            let size = item.label.count
            if size > maxLength {
                return ["label is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class ManualClosureSnapshotCodeLengthRule: ManualClosureSnapshotRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: ManualClosureSnapshot) -> [String] {
            let size = item.code.count
            if size > maxLength {
                return ["code is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class ManualClosureSnapshotQuantityRangeRule: ManualClosureSnapshotRule {
        var min: Int
        var max: Int

        init(min: Int, max: Int) {
            self.min = min
            self.max = max
        }

        func check(_ item: ManualClosureSnapshot) -> [String] {
            let value = item.quantity
            if value < min || value > max {
                return ["quantity \(value) is outside \(min) to \(max)"]
            }
            return []
        }
    }

    final class ManualClosureSnapshotVisibleGuardRule: ManualClosureSnapshotRule {
        var limit: Double

        init(limit: Double) {
            self.limit = limit
        }

        func check(_ item: ManualClosureSnapshot) -> [String] {
            if item.visible && (item.score > limit) {
                return ["score \(item.score) exceeds \(limit) while visible"]
            }
            return []
        }
    }

    final class ManualClosureSnapshotCreatedAtRangeRule: ManualClosureSnapshotRule {
        var min: Int
        var max: Int

        init(min: Int, max: Int) {
            self.min = min
            self.max = max
        }

        func check(_ item: ManualClosureSnapshot) -> [String] {
            let value = item.createdAt
            if value < min || value > max {
                return ["created at \(value) is outside \(min) to \(max)"]
            }
            return []
        }
    }

    final class ManualClosureSnapshotRequiredLabelRule: ManualClosureSnapshotRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: ManualClosureSnapshot) -> [String] {
            if item.label.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    /// Runs every rule of a manual closure snapshot.
    final class ManualClosureSnapshotValidator {
        var rules: [any ManualClosureSnapshotRule]

        init(rules: [any ManualClosureSnapshotRule]) {
            self.rules = rules
        }

        func validate(_ item: ManualClosureSnapshot) -> [String] {
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

        func requireValid(_ item: ManualClosureSnapshot) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.displayLabel()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [ManualClosureSnapshot]) -> [String: [String]] {
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

    static func defaultManualClosureSnapshotValidator() -> ManualClosureSnapshotValidator {
        return ManualClosureSnapshotValidator(
            rules: [
                ManualClosureSnapshotLabelLengthRule(maxLength: 1000),
                ManualClosureSnapshotCodeLengthRule(maxLength: 120),
                ManualClosureSnapshotQuantityRangeRule(min: 120, max: 3600),
                ManualClosureSnapshotVisibleGuardRule(limit: 3.2),
                ManualClosureSnapshotCreatedAtRangeRule(min: 255, max: 86400),
                ManualClosureSnapshotRequiredLabelRule(message: "manual closure snapshot needs a value"),
            ]
        )
    }
}
