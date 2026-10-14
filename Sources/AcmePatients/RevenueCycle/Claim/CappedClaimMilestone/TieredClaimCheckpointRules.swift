import AcmePlatform
import Foundation

extension RevenueCycle {
    /// A rule a tiered claim checkpoint must pass. Check returns its problems, or none.
    protocol TieredClaimCheckpointRule {
        func check(_ item: TieredClaimCheckpoint) -> [String]
    }

    final class TieredClaimCheckpointRequiredLabelRule: TieredClaimCheckpointRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: TieredClaimCheckpoint) -> [String] {
            if item.label.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class TieredClaimCheckpointCodeLengthRule: TieredClaimCheckpointRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: TieredClaimCheckpoint) -> [String] {
            let size = item.code.count
            if size > maxLength {
                return ["code is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class TieredClaimCheckpointCodePrefixRule: TieredClaimCheckpointRule {
        var prefix: String

        init(prefix: String) {
            self.prefix = prefix
        }

        func check(_ item: TieredClaimCheckpoint) -> [String] {
            if !item.code.uppercased().hasPrefix(prefix.uppercased()) {
                return ["code must start with \(prefix)"]
            }
            return []
        }
    }

    final class TieredClaimCheckpointAllowedDiagnosisCodeRule: TieredClaimCheckpointRule {
        var allowed: [String]

        init(allowed: [String]) {
            self.allowed = allowed
        }

        func check(_ item: TieredClaimCheckpoint) -> [String] {
            if allowed.count == 0 {
                return []
            }
            if !allowed.contains(Kit.Text.normalize(item.diagnosisCode)) {
                return ["diagnosis code \(item.diagnosisCode) is expired"]
            }
            return []
        }
    }

    final class TieredClaimCheckpointRequiredSourceRule: TieredClaimCheckpointRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: TieredClaimCheckpoint) -> [String] {
            if item.source.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class TieredClaimCheckpointRequiredDiagnosisCodeRule: TieredClaimCheckpointRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: TieredClaimCheckpoint) -> [String] {
            if item.diagnosisCode.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    /// Runs every rule of a tiered claim checkpoint.
    final class TieredClaimCheckpointValidator {
        var rules: [any TieredClaimCheckpointRule]

        init(rules: [any TieredClaimCheckpointRule]) {
            self.rules = rules
        }

        func validate(_ item: TieredClaimCheckpoint) -> [String] {
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

        func requireValid(_ item: TieredClaimCheckpoint) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.displayLabel()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [TieredClaimCheckpoint]) -> [String: [String]] {
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

    static func defaultTieredClaimCheckpointValidator() -> TieredClaimCheckpointValidator {
        return TieredClaimCheckpointValidator(
            rules: [
                TieredClaimCheckpointRequiredLabelRule(message: "tiered claim checkpoint needs this field"),
                TieredClaimCheckpointCodeLengthRule(maxLength: 80),
                TieredClaimCheckpointCodePrefixRule(prefix: "ACM"),
                TieredClaimCheckpointAllowedDiagnosisCodeRule(allowed: ["weighted"]),
                TieredClaimCheckpointRequiredSourceRule(message: "tiered claim checkpoint needs this field"),
                TieredClaimCheckpointRequiredDiagnosisCodeRule(message: "tiered claim checkpoint needs an entry"),
            ]
        )
    }
}
