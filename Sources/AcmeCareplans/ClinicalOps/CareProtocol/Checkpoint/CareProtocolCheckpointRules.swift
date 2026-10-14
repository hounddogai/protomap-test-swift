import AcmePlatform
import Foundation

extension ClinicalOps {
    /// A rule a care protocol checkpoint must pass. Check returns its problems, or none.
    protocol CareProtocolCheckpointRule {
        func check(_ item: CareProtocolCheckpoint) -> [String]
    }

    final class CareProtocolCheckpointRequiredNameRule: CareProtocolCheckpointRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: CareProtocolCheckpoint) -> [String] {
            if item.name.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class CareProtocolCheckpointUnitLengthRule: CareProtocolCheckpointRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: CareProtocolCheckpoint) -> [String] {
            let size = item.unit.count
            if size > maxLength {
                return ["unit is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class CareProtocolCheckpointNameLengthRule: CareProtocolCheckpointRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: CareProtocolCheckpoint) -> [String] {
            let size = item.name.count
            if size > maxLength {
                return ["name is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class CareProtocolCheckpointAllowedNameRule: CareProtocolCheckpointRule {
        var allowed: [String]

        init(allowed: [String]) {
            self.allowed = allowed
        }

        func check(_ item: CareProtocolCheckpoint) -> [String] {
            if allowed.count == 0 {
                return []
            }
            if !allowed.contains(Kit.Text.normalize(item.name)) {
                return ["name \(item.name) is above maximum"]
            }
            return []
        }
    }

    final class CareProtocolCheckpointCodePrefixRule: CareProtocolCheckpointRule {
        var prefix: String

        init(prefix: String) {
            self.prefix = prefix
        }

        func check(_ item: CareProtocolCheckpoint) -> [String] {
            if !item.code.uppercased().hasPrefix(prefix.uppercased()) {
                return ["code must start with \(prefix)"]
            }
            return []
        }
    }

    final class CareProtocolCheckpointRequiredUnitRule: CareProtocolCheckpointRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: CareProtocolCheckpoint) -> [String] {
            if item.unit.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    /// Runs every rule of a care protocol checkpoint.
    final class CareProtocolCheckpointValidator {
        var rules: [any CareProtocolCheckpointRule]

        init(rules: [any CareProtocolCheckpointRule]) {
            self.rules = rules
        }

        func validate(_ item: CareProtocolCheckpoint) -> [String] {
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

        func requireValid(_ item: CareProtocolCheckpoint) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.label()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [CareProtocolCheckpoint]) -> [String: [String]] {
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

    static func defaultCareProtocolCheckpointValidator() -> CareProtocolCheckpointValidator {
        return CareProtocolCheckpointValidator(
            rules: [
                CareProtocolCheckpointRequiredNameRule(message: "care protocol checkpoint needs this field"),
                CareProtocolCheckpointUnitLengthRule(maxLength: 3600),
                CareProtocolCheckpointNameLengthRule(maxLength: 120),
                CareProtocolCheckpointAllowedNameRule(allowed: ["weighted", "fallback", "primary"]),
                CareProtocolCheckpointCodePrefixRule(prefix: "X"),
                CareProtocolCheckpointRequiredUnitRule(message: "care protocol checkpoint needs a value"),
            ]
        )
    }
}
