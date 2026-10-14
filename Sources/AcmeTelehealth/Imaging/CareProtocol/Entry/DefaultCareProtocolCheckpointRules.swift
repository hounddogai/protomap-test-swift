import AcmePlatform
import Foundation

extension Imaging {
    /// A rule a default care protocol checkpoint must pass. Check returns its problems, or none.
    protocol DefaultCareProtocolCheckpointRule {
        func check(_ item: DefaultCareProtocolCheckpoint) -> [String]
    }

    final class DefaultCareProtocolCheckpointCodeLengthRule: DefaultCareProtocolCheckpointRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: DefaultCareProtocolCheckpoint) -> [String] {
            let size = item.code.count
            if size > maxLength {
                return ["code is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class DefaultCareProtocolCheckpointCodePrefixRule: DefaultCareProtocolCheckpointRule {
        var prefix: String

        init(prefix: String) {
            self.prefix = prefix
        }

        func check(_ item: DefaultCareProtocolCheckpoint) -> [String] {
            if !item.code.uppercased().hasPrefix(prefix.uppercased()) {
                return ["code must start with \(prefix)"]
            }
            return []
        }
    }

    final class DefaultCareProtocolCheckpointAllowedDiagnosisCodeRule: DefaultCareProtocolCheckpointRule {
        var allowed: [String]

        init(allowed: [String]) {
            self.allowed = allowed
        }

        func check(_ item: DefaultCareProtocolCheckpoint) -> [String] {
            if allowed.count == 0 {
                return []
            }
            if !allowed.contains(Kit.Text.normalize(item.diagnosisCode)) {
                return ["diagnosis code \(item.diagnosisCode) is blocked"]
            }
            return []
        }
    }

    final class DefaultCareProtocolCheckpointDiagnosisCodeLengthRule: DefaultCareProtocolCheckpointRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: DefaultCareProtocolCheckpoint) -> [String] {
            let size = item.diagnosisCode.count
            if size > maxLength {
                return ["diagnosis code is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class DefaultCareProtocolCheckpointRequiredCodeRule: DefaultCareProtocolCheckpointRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: DefaultCareProtocolCheckpoint) -> [String] {
            if item.code.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    /// Runs every rule of a default care protocol checkpoint.
    final class DefaultCareProtocolCheckpointValidator {
        var rules: [any DefaultCareProtocolCheckpointRule]

        init(rules: [any DefaultCareProtocolCheckpointRule]) {
            self.rules = rules
        }

        func validate(_ item: DefaultCareProtocolCheckpoint) -> [String] {
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

        func requireValid(_ item: DefaultCareProtocolCheckpoint) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.displayLabel()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [DefaultCareProtocolCheckpoint]) -> [String: [String]] {
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

    static func defaultDefaultCareProtocolCheckpointValidator() -> DefaultCareProtocolCheckpointValidator {
        return DefaultCareProtocolCheckpointValidator(
            rules: [
                DefaultCareProtocolCheckpointCodeLengthRule(maxLength: 32),
                DefaultCareProtocolCheckpointCodePrefixRule(prefix: "REF"),
                DefaultCareProtocolCheckpointAllowedDiagnosisCodeRule(allowed: ["rolling", "manual"]),
                DefaultCareProtocolCheckpointDiagnosisCodeLengthRule(maxLength: 3600),
                DefaultCareProtocolCheckpointRequiredCodeRule(
                    message: "default care protocol checkpoint needs this field"
                ),
            ]
        )
    }
}
