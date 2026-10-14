import AcmePlatform
import Foundation

extension Imaging {
    /// A rule a modality snapshot must pass. Check returns its problems, or none.
    protocol ModalitySnapshotRule {
        func check(_ item: ModalitySnapshot) -> [String]
    }

    final class ModalitySnapshotDurationMinutesRangeRule: ModalitySnapshotRule {
        var min: Int
        var max: Int

        init(min: Int, max: Int) {
            self.min = min
            self.max = max
        }

        func check(_ item: ModalitySnapshot) -> [String] {
            let value = item.durationMinutes
            if value < min || value > max {
                return ["duration minutes \(value) is outside \(min) to \(max)"]
            }
            return []
        }
    }

    final class ModalitySnapshotCodePrefixRule: ModalitySnapshotRule {
        var prefix: String

        init(prefix: String) {
            self.prefix = prefix
        }

        func check(_ item: ModalitySnapshot) -> [String] {
            if !item.code.uppercased().hasPrefix(prefix.uppercased()) {
                return ["code must start with \(prefix)"]
            }
            return []
        }
    }

    final class ModalitySnapshotBudgetRangeRule: ModalitySnapshotRule {
        var min: Double
        var max: Double

        init(min: Double, max: Double) {
            self.min = min
            self.max = max
        }

        func check(_ item: ModalitySnapshot) -> [String] {
            let value = item.budget
            var problems: [String] = []
            if value < min {
                problems.append("budget \(value) is below \(min)")
            }
            if value > max {
                problems.append("budget \(value) is above \(max)")
            }
            return problems
        }
    }

    /// Runs every rule of a modality snapshot.
    final class ModalitySnapshotValidator {
        var rules: [any ModalitySnapshotRule]

        init(rules: [any ModalitySnapshotRule]) {
            self.rules = rules
        }

        func validate(_ item: ModalitySnapshot) -> [String] {
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

        func requireValid(_ item: ModalitySnapshot) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.label()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [ModalitySnapshot]) -> [String: [String]] {
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

    static func defaultModalitySnapshotValidator() -> ModalitySnapshotValidator {
        return ModalitySnapshotValidator(
            rules: [
                ModalitySnapshotDurationMinutesRangeRule(min: 80, max: 86400),
                ModalitySnapshotCodePrefixRule(prefix: "OPS"),
                ModalitySnapshotBudgetRangeRule(min: 9.6, max: 1807.9),
            ]
        )
    }
}
