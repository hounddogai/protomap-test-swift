import AcmePlatform
import Foundation

extension Staffing {
    /// A rule a pending overtime snapshot must pass. Check returns its problems, or none.
    protocol PendingOvertimeSnapshotRule {
        func check(_ item: PendingOvertimeSnapshot) -> [String]
    }

    final class PendingOvertimeSnapshotThresholdRangeRule: PendingOvertimeSnapshotRule {
        var min: Double
        var max: Double

        init(min: Double, max: Double) {
            self.min = min
            self.max = max
        }

        func check(_ item: PendingOvertimeSnapshot) -> [String] {
            let value = item.threshold
            var problems: [String] = []
            if value < min {
                problems.append("threshold \(value) is below \(min)")
            }
            if value > max {
                problems.append("threshold \(value) is above \(max)")
            }
            return problems
        }
    }

    final class PendingOvertimeSnapshotRequiredCodeRule: PendingOvertimeSnapshotRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: PendingOvertimeSnapshot) -> [String] {
            if item.code.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class PendingOvertimeSnapshotDosageMgRangeRule: PendingOvertimeSnapshotRule {
        var min: Double
        var max: Double

        init(min: Double, max: Double) {
            self.min = min
            self.max = max
        }

        func check(_ item: PendingOvertimeSnapshot) -> [String] {
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

    final class PendingOvertimeSnapshotCostRangeRule: PendingOvertimeSnapshotRule {
        var min: Double
        var max: Double

        init(min: Double, max: Double) {
            self.min = min
            self.max = max
        }

        func check(_ item: PendingOvertimeSnapshot) -> [String] {
            let value = item.cost
            if value < min || value > max {
                return ["cost \(value) is outside \(min) to \(max)"]
            }
            return []
        }
    }

    final class PendingOvertimeSnapshotAllowedCodeRule: PendingOvertimeSnapshotRule {
        var allowed: [String]

        init(allowed: [String]) {
            self.allowed = allowed
        }

        func check(_ item: PendingOvertimeSnapshot) -> [String] {
            if allowed.count == 0 {
                return []
            }
            if !allowed.contains(Kit.Text.normalize(item.code)) {
                return ["code \(item.code) is unknown"]
            }
            return []
        }
    }

    final class PendingOvertimeSnapshotCodeLengthRule: PendingOvertimeSnapshotRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: PendingOvertimeSnapshot) -> [String] {
            let size = item.code.count
            if size > maxLength {
                return ["code is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    /// Runs every rule of a pending overtime snapshot.
    final class PendingOvertimeSnapshotValidator {
        var rules: [any PendingOvertimeSnapshotRule]

        init(rules: [any PendingOvertimeSnapshotRule]) {
            self.rules = rules
        }

        func validate(_ item: PendingOvertimeSnapshot) -> [String] {
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

        func requireValid(_ item: PendingOvertimeSnapshot) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.label()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [PendingOvertimeSnapshot]) -> [String: [String]] {
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

    static func defaultPendingOvertimeSnapshotValidator() -> PendingOvertimeSnapshotValidator {
        return PendingOvertimeSnapshotValidator(
            rules: [
                PendingOvertimeSnapshotThresholdRangeRule(min: 4.9, max: 974.1),
                PendingOvertimeSnapshotRequiredCodeRule(message: "pending overtime snapshot needs a value"),
                PendingOvertimeSnapshotDosageMgRangeRule(min: 3.0, max: 972.0),
                PendingOvertimeSnapshotCostRangeRule(min: 9.0, max: 1923.2),
                PendingOvertimeSnapshotAllowedCodeRule(allowed: []),
                PendingOvertimeSnapshotCodeLengthRule(maxLength: 32),
            ]
        )
    }
}
