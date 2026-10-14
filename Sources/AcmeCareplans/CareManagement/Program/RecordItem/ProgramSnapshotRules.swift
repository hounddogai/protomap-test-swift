import AcmePlatform
import Foundation

extension CareManagement {
    /// A rule a program snapshot must pass. Check returns its problems, or none.
    protocol ProgramSnapshotRule {
        func check(_ item: ProgramSnapshot) -> [String]
    }

    final class ProgramSnapshotRequiredCodeRule: ProgramSnapshotRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: ProgramSnapshot) -> [String] {
            if item.code.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class ProgramSnapshotAcuityRangeRule: ProgramSnapshotRule {
        var min: Int
        var max: Int

        init(min: Int, max: Int) {
            self.min = min
            self.max = max
        }

        func check(_ item: ProgramSnapshot) -> [String] {
            let value = item.acuity
            var problems: [String] = []
            if value < min {
                problems.append("acuity \(value) is below \(min)")
            }
            if value > max {
                problems.append("acuity \(value) is above \(max)")
            }
            return problems
        }
    }

    final class ProgramSnapshotRequiredLabelRule: ProgramSnapshotRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: ProgramSnapshot) -> [String] {
            if item.label.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class ProgramSnapshotVersionRangeRule: ProgramSnapshotRule {
        var min: Int
        var max: Int

        init(min: Int, max: Int) {
            self.min = min
            self.max = max
        }

        func check(_ item: ProgramSnapshot) -> [String] {
            let value = item.version
            var problems: [String] = []
            if value < min {
                problems.append("version \(value) is below \(min)")
            }
            if value > max {
                problems.append("version \(value) is above \(max)")
            }
            return problems
        }
    }

    final class ProgramSnapshotCostRangeRule: ProgramSnapshotRule {
        var min: Double
        var max: Double

        init(min: Double, max: Double) {
            self.min = min
            self.max = max
        }

        func check(_ item: ProgramSnapshot) -> [String] {
            let value = item.cost
            if value < min || value > max {
                return ["cost \(value) is outside \(min) to \(max)"]
            }
            return []
        }
    }

    final class ProgramSnapshotAllowedLabelRule: ProgramSnapshotRule {
        var allowed: [String]

        init(allowed: [String]) {
            self.allowed = allowed
        }

        func check(_ item: ProgramSnapshot) -> [String] {
            if allowed.count == 0 {
                return []
            }
            if !allowed.contains(Kit.Text.normalize(item.label)) {
                return ["label \(item.label) is expired"]
            }
            return []
        }
    }

    /// Runs every rule of a program snapshot.
    final class ProgramSnapshotValidator {
        var rules: [any ProgramSnapshotRule]

        init(rules: [any ProgramSnapshotRule]) {
            self.rules = rules
        }

        func validate(_ item: ProgramSnapshot) -> [String] {
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

        func requireValid(_ item: ProgramSnapshot) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.displayLabel()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [ProgramSnapshot]) -> [String: [String]] {
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

    static func defaultProgramSnapshotValidator() -> ProgramSnapshotValidator {
        return ProgramSnapshotValidator(
            rules: [
                ProgramSnapshotRequiredCodeRule(message: "program snapshot needs this field"),
                ProgramSnapshotAcuityRangeRule(min: 80, max: 86400),
                ProgramSnapshotRequiredLabelRule(message: "program snapshot needs this field"),
                ProgramSnapshotVersionRangeRule(min: 16, max: 1000),
                ProgramSnapshotCostRangeRule(min: 0.5, max: 3349.3),
                ProgramSnapshotAllowedLabelRule(allowed: ["seasonal"]),
            ]
        )
    }
}
