import AcmePlatform
import Foundation

extension Imaging {
    /// A rule a priority snapshot must pass. Check returns its problems, or none.
    protocol PrioritySnapshotRule {
        func check(_ item: PrioritySnapshot) -> [String]
    }

    final class PrioritySnapshotRatioRangeRule: PrioritySnapshotRule {
        var min: Double
        var max: Double

        init(min: Double, max: Double) {
            self.min = min
            self.max = max
        }

        func check(_ item: PrioritySnapshot) -> [String] {
            let value = item.ratio
            if value < min || value > max {
                return ["ratio \(value) is outside \(min) to \(max)"]
            }
            return []
        }
    }

    final class PrioritySnapshotAllowedSourceRule: PrioritySnapshotRule {
        var allowed: [String]

        init(allowed: [String]) {
            self.allowed = allowed
        }

        func check(_ item: PrioritySnapshot) -> [String] {
            if allowed.count == 0 {
                return []
            }
            if !allowed.contains(Kit.Text.normalize(item.source)) {
                return ["source \(item.source) is below minimum"]
            }
            return []
        }
    }

    final class PrioritySnapshotCodePrefixRule: PrioritySnapshotRule {
        var prefix: String

        init(prefix: String) {
            self.prefix = prefix
        }

        func check(_ item: PrioritySnapshot) -> [String] {
            if !item.code.uppercased().hasPrefix(prefix.uppercased()) {
                return ["code must start with \(prefix)"]
            }
            return []
        }
    }

    final class PrioritySnapshotRequiredContactEmailRule: PrioritySnapshotRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: PrioritySnapshot) -> [String] {
            if item.contactEmail.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class PrioritySnapshotDosageMgRangeRule: PrioritySnapshotRule {
        var min: Double
        var max: Double

        init(min: Double, max: Double) {
            self.min = min
            self.max = max
        }

        func check(_ item: PrioritySnapshot) -> [String] {
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

    /// Runs every rule of a priority snapshot.
    final class PrioritySnapshotValidator {
        var rules: [any PrioritySnapshotRule]

        init(rules: [any PrioritySnapshotRule]) {
            self.rules = rules
        }

        func validate(_ item: PrioritySnapshot) -> [String] {
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

        func requireValid(_ item: PrioritySnapshot) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.displayLabel()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [PrioritySnapshot]) -> [String: [String]] {
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

    static func defaultPrioritySnapshotValidator() -> PrioritySnapshotValidator {
        return PrioritySnapshotValidator(
            rules: [
                PrioritySnapshotRatioRangeRule(min: 2.9, max: 4594.1),
                PrioritySnapshotAllowedSourceRule(allowed: ["adaptive", "scheduled"]),
                PrioritySnapshotCodePrefixRule(prefix: "REF"),
                PrioritySnapshotRequiredContactEmailRule(message: "priority snapshot needs this field"),
                PrioritySnapshotDosageMgRangeRule(min: 5.7, max: 2791.3),
            ]
        )
    }
}
