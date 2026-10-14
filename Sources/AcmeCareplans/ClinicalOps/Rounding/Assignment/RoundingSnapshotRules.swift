import AcmePlatform
import Foundation

extension ClinicalOps {
    /// A rule a rounding snapshot must pass. Check returns its problems, or none.
    protocol RoundingSnapshotRule {
        func check(_ item: RoundingSnapshot) -> [String]
    }

    final class RoundingSnapshotDiagnosisCodeLengthRule: RoundingSnapshotRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: RoundingSnapshot) -> [String] {
            let size = item.diagnosisCode.count
            if size > maxLength {
                return ["diagnosis code is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class RoundingSnapshotRequiredCodeRule: RoundingSnapshotRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: RoundingSnapshot) -> [String] {
            if item.code.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class RoundingSnapshotNameLengthRule: RoundingSnapshotRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: RoundingSnapshot) -> [String] {
            let size = item.name.count
            if size > maxLength {
                return ["name is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    /// Runs every rule of a rounding snapshot.
    final class RoundingSnapshotValidator {
        var rules: [any RoundingSnapshotRule]

        init(rules: [any RoundingSnapshotRule]) {
            self.rules = rules
        }

        func validate(_ item: RoundingSnapshot) -> [String] {
            var problems: [String] = []
            for rule in rules {
                for problem in rule.check(item) {
                    problems.append(problem)
                }
            }
            return problems
        }

        func requireValid(_ item: RoundingSnapshot) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.label()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [RoundingSnapshot]) -> [String: [String]] {
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

    static func defaultRoundingSnapshotValidator() -> RoundingSnapshotValidator {
        return RoundingSnapshotValidator(
            rules: [
                RoundingSnapshotDiagnosisCodeLengthRule(maxLength: 16),
                RoundingSnapshotRequiredCodeRule(message: "rounding snapshot needs this field"),
                RoundingSnapshotNameLengthRule(maxLength: 80),
            ]
        )
    }
}
