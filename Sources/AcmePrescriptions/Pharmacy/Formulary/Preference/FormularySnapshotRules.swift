import AcmePlatform
import Foundation

extension Pharmacy {
    /// A rule a formulary snapshot must pass. Check returns its problems, or none.
    protocol FormularySnapshotRule {
        func check(_ item: FormularySnapshot) -> [String]
    }

    final class FormularySnapshotMaximumRangeRule: FormularySnapshotRule {
        var min: Double
        var max: Double

        init(min: Double, max: Double) {
            self.min = min
            self.max = max
        }

        func check(_ item: FormularySnapshot) -> [String] {
            let value = item.maximum
            if value < min || value > max {
                return ["maximum \(value) is outside \(min) to \(max)"]
            }
            return []
        }
    }

    final class FormularySnapshotAllowedCodeRule: FormularySnapshotRule {
        var allowed: [String]

        init(allowed: [String]) {
            self.allowed = allowed
        }

        func check(_ item: FormularySnapshot) -> [String] {
            if allowed.count == 0 {
                return []
            }
            if !allowed.contains(Kit.Text.normalize(item.code)) {
                return ["code \(item.code) is below minimum"]
            }
            return []
        }
    }

    final class FormularySnapshotApprovedGuardRule: FormularySnapshotRule {
        var limit: Double

        init(limit: Double) {
            self.limit = limit
        }

        func check(_ item: FormularySnapshot) -> [String] {
            if item.approved && (item.maximum > limit) {
                return ["maximum \(item.maximum) exceeds \(limit) while approved"]
            }
            return []
        }
    }

    final class FormularySnapshotRatioRangeRule: FormularySnapshotRule {
        var min: Double
        var max: Double

        init(min: Double, max: Double) {
            self.min = min
            self.max = max
        }

        func check(_ item: FormularySnapshot) -> [String] {
            let value = item.ratio
            if value < min || value > max {
                return ["ratio \(value) is outside \(min) to \(max)"]
            }
            return []
        }
    }

    /// Runs every rule of a formulary snapshot.
    final class FormularySnapshotValidator {
        var rules: [any FormularySnapshotRule]

        init(rules: [any FormularySnapshotRule]) {
            self.rules = rules
        }

        func validate(_ item: FormularySnapshot) -> [String] {
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

        func requireValid(_ item: FormularySnapshot) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.label()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [FormularySnapshot]) -> [String: [String]] {
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

    static func defaultFormularySnapshotValidator() -> FormularySnapshotValidator {
        return FormularySnapshotValidator(
            rules: [
                FormularySnapshotMaximumRangeRule(min: 3.1, max: 2713.8),
                FormularySnapshotAllowedCodeRule(allowed: ["tiered", "primary", "primary"]),
                FormularySnapshotApprovedGuardRule(limit: 8.1),
                FormularySnapshotRatioRangeRule(min: 0.4, max: 460.8),
            ]
        )
    }
}
