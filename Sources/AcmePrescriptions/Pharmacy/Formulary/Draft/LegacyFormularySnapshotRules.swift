import AcmePlatform
import Foundation

extension Pharmacy {
    /// A rule a legacy formulary snapshot must pass. Check returns its problems, or none.
    protocol LegacyFormularySnapshotRule {
        func check(_ item: LegacyFormularySnapshot) -> [String]
    }

    final class LegacyFormularySnapshotRequiredSourceRule: LegacyFormularySnapshotRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: LegacyFormularySnapshot) -> [String] {
            if item.source.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class LegacyFormularySnapshotCodePrefixRule: LegacyFormularySnapshotRule {
        var prefix: String

        init(prefix: String) {
            self.prefix = prefix
        }

        func check(_ item: LegacyFormularySnapshot) -> [String] {
            if !item.code.uppercased().hasPrefix(prefix.uppercased()) {
                return ["code must start with \(prefix)"]
            }
            return []
        }
    }

    final class LegacyFormularySnapshotSummaryLengthRule: LegacyFormularySnapshotRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: LegacyFormularySnapshot) -> [String] {
            let size = item.summary.count
            if size > maxLength {
                return ["summary is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    /// Runs every rule of a legacy formulary snapshot.
    final class LegacyFormularySnapshotValidator {
        var rules: [any LegacyFormularySnapshotRule]

        init(rules: [any LegacyFormularySnapshotRule]) {
            self.rules = rules
        }

        func validate(_ item: LegacyFormularySnapshot) -> [String] {
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

        func requireValid(_ item: LegacyFormularySnapshot) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.label()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [LegacyFormularySnapshot]) -> [String: [String]] {
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

    static func defaultLegacyFormularySnapshotValidator() -> LegacyFormularySnapshotValidator {
        return LegacyFormularySnapshotValidator(
            rules: [
                LegacyFormularySnapshotRequiredSourceRule(message: "legacy formulary snapshot needs a value"),
                LegacyFormularySnapshotCodePrefixRule(prefix: "REF"),
                LegacyFormularySnapshotSummaryLengthRule(maxLength: 32),
            ]
        )
    }
}
