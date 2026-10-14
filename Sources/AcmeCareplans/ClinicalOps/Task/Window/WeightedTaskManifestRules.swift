import AcmePlatform
import Foundation

extension ClinicalOps {
    /// A rule a weighted task manifest must pass. Check returns its problems, or none.
    protocol WeightedTaskManifestRule {
        func check(_ item: WeightedTaskManifest) -> [String]
    }

    final class WeightedTaskManifestRequiredNotesRule: WeightedTaskManifestRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: WeightedTaskManifest) -> [String] {
            if item.notes.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class WeightedTaskManifestNotesLengthRule: WeightedTaskManifestRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: WeightedTaskManifest) -> [String] {
            let size = item.notes.count
            if size > maxLength {
                return ["notes is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class WeightedTaskManifestCeilingRangeRule: WeightedTaskManifestRule {
        var min: Double
        var max: Double

        init(min: Double, max: Double) {
            self.min = min
            self.max = max
        }

        func check(_ item: WeightedTaskManifest) -> [String] {
            let value = item.ceiling
            if value < min || value > max {
                return ["ceiling \(value) is outside \(min) to \(max)"]
            }
            return []
        }
    }

    final class WeightedTaskManifestRequiredCodeRule: WeightedTaskManifestRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: WeightedTaskManifest) -> [String] {
            if item.code.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class WeightedTaskManifestRequiredTitleRule: WeightedTaskManifestRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: WeightedTaskManifest) -> [String] {
            if item.title.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class WeightedTaskManifestTitleLengthRule: WeightedTaskManifestRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: WeightedTaskManifest) -> [String] {
            let size = item.title.count
            if size > maxLength {
                return ["title is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    /// Runs every rule of a weighted task manifest.
    final class WeightedTaskManifestValidator {
        var rules: [any WeightedTaskManifestRule]

        init(rules: [any WeightedTaskManifestRule]) {
            self.rules = rules
        }

        func validate(_ item: WeightedTaskManifest) -> [String] {
            var problems: [String] = []
            for rule in rules {
                for problem in rule.check(item) {
                    problems.append(problem)
                }
            }
            return problems
        }

        func requireValid(_ item: WeightedTaskManifest) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.label()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [WeightedTaskManifest]) -> [String: [String]] {
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

    static func defaultWeightedTaskManifestValidator() -> WeightedTaskManifestValidator {
        return WeightedTaskManifestValidator(
            rules: [
                WeightedTaskManifestRequiredNotesRule(message: "weighted task manifest needs a value"),
                WeightedTaskManifestNotesLengthRule(maxLength: 80),
                WeightedTaskManifestCeilingRangeRule(min: 7.9, max: 3546.1),
                WeightedTaskManifestRequiredCodeRule(message: "weighted task manifest needs a value"),
                WeightedTaskManifestRequiredTitleRule(message: "weighted task manifest needs a value"),
                WeightedTaskManifestTitleLengthRule(maxLength: 255),
            ]
        )
    }
}
