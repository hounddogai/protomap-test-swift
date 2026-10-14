import AcmePlatform
import Foundation

extension Staffing {
    /// A rule a primary acuity plan snapshot must pass. Check returns its problems, or none.
    protocol PrimaryAcuityPlanSnapshotRule {
        func check(_ item: PrimaryAcuityPlanSnapshot) -> [String]
    }

    final class PrimaryAcuityPlanSnapshotPatientRefLengthRule: PrimaryAcuityPlanSnapshotRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: PrimaryAcuityPlanSnapshot) -> [String] {
            let size = item.patientRef.count
            if size > maxLength {
                return ["patient ref is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class PrimaryAcuityPlanSnapshotScoreRangeRule: PrimaryAcuityPlanSnapshotRule {
        var min: Double
        var max: Double

        init(min: Double, max: Double) {
            self.min = min
            self.max = max
        }

        func check(_ item: PrimaryAcuityPlanSnapshot) -> [String] {
            let value = item.score
            if value < min || value > max {
                return ["score \(value) is outside \(min) to \(max)"]
            }
            return []
        }
    }

    final class PrimaryAcuityPlanSnapshotCodePrefixRule: PrimaryAcuityPlanSnapshotRule {
        var prefix: String

        init(prefix: String) {
            self.prefix = prefix
        }

        func check(_ item: PrimaryAcuityPlanSnapshot) -> [String] {
            if !item.code.uppercased().hasPrefix(prefix.uppercased()) {
                return ["code must start with \(prefix)"]
            }
            return []
        }
    }

    /// Runs every rule of a primary acuity plan snapshot.
    final class PrimaryAcuityPlanSnapshotValidator {
        var rules: [any PrimaryAcuityPlanSnapshotRule]

        init(rules: [any PrimaryAcuityPlanSnapshotRule]) {
            self.rules = rules
        }

        func validate(_ item: PrimaryAcuityPlanSnapshot) -> [String] {
            var problems: [String] = []
            for rule in rules {
                for problem in rule.check(item) {
                    problems.append(problem)
                }
            }
            return problems
        }

        func requireValid(_ item: PrimaryAcuityPlanSnapshot) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.displayLabel()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [PrimaryAcuityPlanSnapshot]) -> [String: [String]] {
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

    static func defaultPrimaryAcuityPlanSnapshotValidator() -> PrimaryAcuityPlanSnapshotValidator {
        return PrimaryAcuityPlanSnapshotValidator(
            rules: [
                PrimaryAcuityPlanSnapshotPatientRefLengthRule(maxLength: 3600),
                PrimaryAcuityPlanSnapshotScoreRangeRule(min: 9.4, max: 3101.2),
                PrimaryAcuityPlanSnapshotCodePrefixRule(prefix: "REF"),
            ]
        )
    }
}
