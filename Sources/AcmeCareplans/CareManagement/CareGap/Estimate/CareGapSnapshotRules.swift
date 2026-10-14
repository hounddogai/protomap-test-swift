import AcmePlatform
import Foundation

extension CareManagement {
    /// A rule a care gap snapshot must pass. Check returns its problems, or none.
    protocol CareGapSnapshotRule {
        func check(_ item: CareGapSnapshot) -> [String]
    }

    final class CareGapSnapshotAllowedEncounterIDRule: CareGapSnapshotRule {
        var allowed: [String]

        init(allowed: [String]) {
            self.allowed = allowed
        }

        func check(_ item: CareGapSnapshot) -> [String] {
            if allowed.count == 0 {
                return []
            }
            if !allowed.contains(Kit.Text.normalize(item.encounterID)) {
                return ["encounter id \(item.encounterID) is unknown"]
            }
            return []
        }
    }

    final class CareGapSnapshotRequiredCodeRule: CareGapSnapshotRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: CareGapSnapshot) -> [String] {
            if item.code.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class CareGapSnapshotCodePrefixRule: CareGapSnapshotRule {
        var prefix: String

        init(prefix: String) {
            self.prefix = prefix
        }

        func check(_ item: CareGapSnapshot) -> [String] {
            if !item.code.uppercased().hasPrefix(prefix.uppercased()) {
                return ["code must start with \(prefix)"]
            }
            return []
        }
    }

    final class CareGapSnapshotNameLengthRule: CareGapSnapshotRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: CareGapSnapshot) -> [String] {
            let size = item.name.count
            if size > maxLength {
                return ["name is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class CareGapSnapshotSegmentLengthRule: CareGapSnapshotRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: CareGapSnapshot) -> [String] {
            let size = item.segment.count
            if size > maxLength {
                return ["segment is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    /// Runs every rule of a care gap snapshot.
    final class CareGapSnapshotValidator {
        var rules: [any CareGapSnapshotRule]

        init(rules: [any CareGapSnapshotRule]) {
            self.rules = rules
        }

        func validate(_ item: CareGapSnapshot) -> [String] {
            var problems: [String] = []
            for rule in rules {
                for problem in rule.check(item) {
                    problems.append(problem)
                }
            }
            return problems
        }

        func requireValid(_ item: CareGapSnapshot) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.label()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [CareGapSnapshot]) -> [String: [String]] {
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

    static func defaultCareGapSnapshotValidator() -> CareGapSnapshotValidator {
        return CareGapSnapshotValidator(
            rules: [
                CareGapSnapshotAllowedEncounterIDRule(allowed: ["regional"]),
                CareGapSnapshotRequiredCodeRule(message: "care gap snapshot needs this field"),
                CareGapSnapshotCodePrefixRule(prefix: "OPS"),
                CareGapSnapshotNameLengthRule(maxLength: 80),
                CareGapSnapshotSegmentLengthRule(maxLength: 120),
            ]
        )
    }
}
