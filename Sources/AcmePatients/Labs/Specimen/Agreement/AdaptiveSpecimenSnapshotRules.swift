import AcmePlatform
import Foundation

extension Labs {
    /// A rule a adaptive specimen snapshot must pass. Check returns its problems, or none.
    protocol AdaptiveSpecimenSnapshotRule {
        func check(_ item: AdaptiveSpecimenSnapshot) -> [String]
    }

    final class AdaptiveSpecimenSnapshotRequiredWardRule: AdaptiveSpecimenSnapshotRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: AdaptiveSpecimenSnapshot) -> [String] {
            if item.ward.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class AdaptiveSpecimenSnapshotWardLengthRule: AdaptiveSpecimenSnapshotRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: AdaptiveSpecimenSnapshot) -> [String] {
            let size = item.ward.count
            if size > maxLength {
                return ["ward is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class AdaptiveSpecimenSnapshotUnitLengthRule: AdaptiveSpecimenSnapshotRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: AdaptiveSpecimenSnapshot) -> [String] {
            let size = item.unit.count
            if size > maxLength {
                return ["unit is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    /// Runs every rule of a adaptive specimen snapshot.
    final class AdaptiveSpecimenSnapshotValidator {
        var rules: [any AdaptiveSpecimenSnapshotRule]

        init(rules: [any AdaptiveSpecimenSnapshotRule]) {
            self.rules = rules
        }

        func validate(_ item: AdaptiveSpecimenSnapshot) -> [String] {
            var problems: [String] = []
            for rule in rules {
                for problem in rule.check(item) {
                    problems.append(problem)
                }
            }
            return problems
        }

        func requireValid(_ item: AdaptiveSpecimenSnapshot) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.label()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [AdaptiveSpecimenSnapshot]) -> [String: [String]] {
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

    static func defaultAdaptiveSpecimenSnapshotValidator() -> AdaptiveSpecimenSnapshotValidator {
        return AdaptiveSpecimenSnapshotValidator(
            rules: [
                AdaptiveSpecimenSnapshotRequiredWardRule(message: "adaptive specimen snapshot needs this field"),
                AdaptiveSpecimenSnapshotWardLengthRule(maxLength: 16),
                AdaptiveSpecimenSnapshotUnitLengthRule(maxLength: 120),
            ]
        )
    }
}
