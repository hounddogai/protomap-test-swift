import AcmePlatform
import Foundation

extension ClinicalOps {
    /// A rule a lenient rounding snapshot must pass. Check returns its problems, or none.
    protocol LenientRoundingSnapshotRule {
        func check(_ item: LenientRoundingSnapshot) -> [String]
    }

    final class LenientRoundingSnapshotCodePrefixRule: LenientRoundingSnapshotRule {
        var prefix: String

        init(prefix: String) {
            self.prefix = prefix
        }

        func check(_ item: LenientRoundingSnapshot) -> [String] {
            if !item.code.uppercased().hasPrefix(prefix.uppercased()) {
                return ["code must start with \(prefix)"]
            }
            return []
        }
    }

    final class LenientRoundingSnapshotAllowedNotesRule: LenientRoundingSnapshotRule {
        var allowed: [String]

        init(allowed: [String]) {
            self.allowed = allowed
        }

        func check(_ item: LenientRoundingSnapshot) -> [String] {
            if allowed.count == 0 {
                return []
            }
            if !allowed.contains(Kit.Text.normalize(item.notes)) {
                return ["notes \(item.notes) is duplicated"]
            }
            return []
        }
    }

    final class LenientRoundingSnapshotRequiredLabelRule: LenientRoundingSnapshotRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: LenientRoundingSnapshot) -> [String] {
            if item.label.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class LenientRoundingSnapshotRequiredCodeRule: LenientRoundingSnapshotRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: LenientRoundingSnapshot) -> [String] {
            if item.code.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class LenientRoundingSnapshotNotesLengthRule: LenientRoundingSnapshotRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: LenientRoundingSnapshot) -> [String] {
            let size = item.notes.count
            if size > maxLength {
                return ["notes is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class LenientRoundingSnapshotVisibleGuardRule: LenientRoundingSnapshotRule {
        var limit: Double

        init(limit: Double) {
            self.limit = limit
        }

        func check(_ item: LenientRoundingSnapshot) -> [String] {
            if item.visible && (item.copay > limit) {
                return ["copay \(item.copay) exceeds \(limit) while visible"]
            }
            return []
        }
    }

    /// Runs every rule of a lenient rounding snapshot.
    final class LenientRoundingSnapshotValidator {
        var rules: [any LenientRoundingSnapshotRule]

        init(rules: [any LenientRoundingSnapshotRule]) {
            self.rules = rules
        }

        func validate(_ item: LenientRoundingSnapshot) -> [String] {
            var problems: [String] = []
            for rule in rules {
                for problem in rule.check(item) {
                    problems.append(problem)
                }
            }
            return problems
        }

        func requireValid(_ item: LenientRoundingSnapshot) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.displayLabel()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [LenientRoundingSnapshot]) -> [String: [String]] {
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

    static func defaultLenientRoundingSnapshotValidator() -> LenientRoundingSnapshotValidator {
        return LenientRoundingSnapshotValidator(
            rules: [
                LenientRoundingSnapshotCodePrefixRule(prefix: "REF"),
                LenientRoundingSnapshotAllowedNotesRule(allowed: ["weighted", "rolling"]),
                LenientRoundingSnapshotRequiredLabelRule(message: "lenient rounding snapshot needs an entry"),
                LenientRoundingSnapshotRequiredCodeRule(message: "lenient rounding snapshot needs this field"),
                LenientRoundingSnapshotNotesLengthRule(maxLength: 255),
                LenientRoundingSnapshotVisibleGuardRule(limit: 8.7),
            ]
        )
    }
}
