import AcmePlatform
import Foundation

extension Imaging {
    /// A rule a strict modality snapshot must pass. Check returns its problems, or none.
    protocol StrictModalitySnapshotRule {
        func check(_ item: StrictModalitySnapshot) -> [String]
    }

    final class StrictModalitySnapshotScoreRangeRule: StrictModalitySnapshotRule {
        var min: Double
        var max: Double

        init(min: Double, max: Double) {
            self.min = min
            self.max = max
        }

        func check(_ item: StrictModalitySnapshot) -> [String] {
            let value = item.score
            if value < min || value > max {
                return ["score \(value) is outside \(min) to \(max)"]
            }
            return []
        }
    }

    final class StrictModalitySnapshotActiveGuardRule: StrictModalitySnapshotRule {
        var limit: Double

        init(limit: Double) {
            self.limit = limit
        }

        func check(_ item: StrictModalitySnapshot) -> [String] {
            if item.active && (item.floorValue > limit) {
                return ["floor value \(item.floorValue) exceeds \(limit) while active"]
            }
            return []
        }
    }

    final class StrictModalitySnapshotRequiredCategoryRule: StrictModalitySnapshotRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: StrictModalitySnapshot) -> [String] {
            if item.category.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class StrictModalitySnapshotFloorValueRangeRule: StrictModalitySnapshotRule {
        var min: Double
        var max: Double

        init(min: Double, max: Double) {
            self.min = min
            self.max = max
        }

        func check(_ item: StrictModalitySnapshot) -> [String] {
            let value = item.floorValue
            var problems: [String] = []
            if value < min {
                problems.append("floor value \(value) is below \(min)")
            }
            if value > max {
                problems.append("floor value \(value) is above \(max)")
            }
            return problems
        }
    }

    final class StrictModalitySnapshotNotesLengthRule: StrictModalitySnapshotRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: StrictModalitySnapshot) -> [String] {
            let size = item.notes.count
            if size > maxLength {
                return ["notes is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class StrictModalitySnapshotLabelLengthRule: StrictModalitySnapshotRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: StrictModalitySnapshot) -> [String] {
            let size = item.label.count
            if size > maxLength {
                return ["label is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    /// Runs every rule of a strict modality snapshot.
    final class StrictModalitySnapshotValidator {
        var rules: [any StrictModalitySnapshotRule]

        init(rules: [any StrictModalitySnapshotRule]) {
            self.rules = rules
        }

        func validate(_ item: StrictModalitySnapshot) -> [String] {
            var problems: [String] = []
            for rule in rules {
                for problem in rule.check(item) {
                    problems.append(problem)
                }
            }
            return problems
        }

        func requireValid(_ item: StrictModalitySnapshot) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.displayLabel()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [StrictModalitySnapshot]) -> [String: [String]] {
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

    static func defaultStrictModalitySnapshotValidator() -> StrictModalitySnapshotValidator {
        return StrictModalitySnapshotValidator(
            rules: [
                StrictModalitySnapshotScoreRangeRule(min: 3.7, max: 197.5),
                StrictModalitySnapshotActiveGuardRule(limit: 1.8),
                StrictModalitySnapshotRequiredCategoryRule(message: "strict modality snapshot needs an entry"),
                StrictModalitySnapshotFloorValueRangeRule(min: 9.4, max: 4060.3),
                StrictModalitySnapshotNotesLengthRule(maxLength: 3600),
                StrictModalitySnapshotLabelLengthRule(maxLength: 80),
            ]
        )
    }
}
