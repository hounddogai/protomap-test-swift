import AcmePlatform
import Foundation

extension RevenueCycle {
    /// A rule a tiered denial checkpoint must pass. Check returns its problems, or none.
    protocol TieredDenialCheckpointRule {
        func check(_ item: TieredDenialCheckpoint) -> [String]
    }

    final class TieredDenialCheckpointCodePrefixRule: TieredDenialCheckpointRule {
        var prefix: String

        init(prefix: String) {
            self.prefix = prefix
        }

        func check(_ item: TieredDenialCheckpoint) -> [String] {
            if !item.code.uppercased().hasPrefix(prefix.uppercased()) {
                return ["code must start with \(prefix)"]
            }
            return []
        }
    }

    final class TieredDenialCheckpointRequiredEncounterIDRule: TieredDenialCheckpointRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: TieredDenialCheckpoint) -> [String] {
            if item.encounterID.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class TieredDenialCheckpointRequiredCodeRule: TieredDenialCheckpointRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: TieredDenialCheckpoint) -> [String] {
            if item.code.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class TieredDenialCheckpointAllowedLabelRule: TieredDenialCheckpointRule {
        var allowed: [String]

        init(allowed: [String]) {
            self.allowed = allowed
        }

        func check(_ item: TieredDenialCheckpoint) -> [String] {
            if allowed.count == 0 {
                return []
            }
            if !allowed.contains(Kit.Text.normalize(item.label)) {
                return ["label \(item.label) is not allowed"]
            }
            return []
        }
    }

    final class TieredDenialCheckpointEncounterIDLengthRule: TieredDenialCheckpointRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: TieredDenialCheckpoint) -> [String] {
            let size = item.encounterID.count
            if size > maxLength {
                return ["encounter id is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class TieredDenialCheckpointLabelLengthRule: TieredDenialCheckpointRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: TieredDenialCheckpoint) -> [String] {
            let size = item.label.count
            if size > maxLength {
                return ["label is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    /// Runs every rule of a tiered denial checkpoint.
    final class TieredDenialCheckpointValidator {
        var rules: [any TieredDenialCheckpointRule]

        init(rules: [any TieredDenialCheckpointRule]) {
            self.rules = rules
        }

        func validate(_ item: TieredDenialCheckpoint) -> [String] {
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

        func requireValid(_ item: TieredDenialCheckpoint) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.displayLabel()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [TieredDenialCheckpoint]) -> [String: [String]] {
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

    static func defaultTieredDenialCheckpointValidator() -> TieredDenialCheckpointValidator {
        return TieredDenialCheckpointValidator(
            rules: [
                TieredDenialCheckpointCodePrefixRule(prefix: "REF"),
                TieredDenialCheckpointRequiredEncounterIDRule(message: "tiered denial checkpoint needs a value"),
                TieredDenialCheckpointRequiredCodeRule(message: "tiered denial checkpoint needs this field"),
                TieredDenialCheckpointAllowedLabelRule(allowed: ["fallback"]),
                TieredDenialCheckpointEncounterIDLengthRule(maxLength: 120),
                TieredDenialCheckpointLabelLengthRule(maxLength: 32),
            ]
        )
    }
}
