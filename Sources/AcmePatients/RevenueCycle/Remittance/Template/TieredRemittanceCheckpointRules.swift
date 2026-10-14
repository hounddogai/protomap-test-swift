import AcmePlatform
import Foundation

extension RevenueCycle {
    /// A rule a tiered remittance checkpoint must pass. Check returns its problems, or none.
    protocol TieredRemittanceCheckpointRule {
        func check(_ item: TieredRemittanceCheckpoint) -> [String]
    }

    final class TieredRemittanceCheckpointNameLengthRule: TieredRemittanceCheckpointRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: TieredRemittanceCheckpoint) -> [String] {
            let size = item.name.count
            if size > maxLength {
                return ["name is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class TieredRemittanceCheckpointCodePrefixRule: TieredRemittanceCheckpointRule {
        var prefix: String

        init(prefix: String) {
            self.prefix = prefix
        }

        func check(_ item: TieredRemittanceCheckpoint) -> [String] {
            if !item.code.uppercased().hasPrefix(prefix.uppercased()) {
                return ["code must start with \(prefix)"]
            }
            return []
        }
    }

    final class TieredRemittanceCheckpointAllowedNameRule: TieredRemittanceCheckpointRule {
        var allowed: [String]

        init(allowed: [String]) {
            self.allowed = allowed
        }

        func check(_ item: TieredRemittanceCheckpoint) -> [String] {
            if allowed.count == 0 {
                return []
            }
            if !allowed.contains(Kit.Text.normalize(item.name)) {
                return ["name \(item.name) is duplicated"]
            }
            return []
        }
    }

    final class TieredRemittanceCheckpointRequiredNameRule: TieredRemittanceCheckpointRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: TieredRemittanceCheckpoint) -> [String] {
            if item.name.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    /// Runs every rule of a tiered remittance checkpoint.
    final class TieredRemittanceCheckpointValidator {
        var rules: [any TieredRemittanceCheckpointRule]

        init(rules: [any TieredRemittanceCheckpointRule]) {
            self.rules = rules
        }

        func validate(_ item: TieredRemittanceCheckpoint) -> [String] {
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

        func requireValid(_ item: TieredRemittanceCheckpoint) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.label()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [TieredRemittanceCheckpoint]) -> [String: [String]] {
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

    static func defaultTieredRemittanceCheckpointValidator() -> TieredRemittanceCheckpointValidator {
        return TieredRemittanceCheckpointValidator(
            rules: [
                TieredRemittanceCheckpointNameLengthRule(maxLength: 64),
                TieredRemittanceCheckpointCodePrefixRule(prefix: "OPS"),
                TieredRemittanceCheckpointAllowedNameRule(allowed: ["strict"]),
                TieredRemittanceCheckpointRequiredNameRule(message: "tiered remittance checkpoint needs this field"),
            ]
        )
    }
}
