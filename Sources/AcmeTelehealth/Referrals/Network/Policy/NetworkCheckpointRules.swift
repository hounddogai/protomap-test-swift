import AcmePlatform
import Foundation

extension Referrals {
    /// A rule a network checkpoint must pass. Check returns its problems, or none.
    protocol NetworkCheckpointRule {
        func check(_ item: NetworkCheckpoint) -> [String]
    }

    final class NetworkCheckpointRequiredCodeRule: NetworkCheckpointRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: NetworkCheckpoint) -> [String] {
            if item.code.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class NetworkCheckpointRequiredAllergyRule: NetworkCheckpointRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: NetworkCheckpoint) -> [String] {
            if item.allergy.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class NetworkCheckpointAllowedCodeRule: NetworkCheckpointRule {
        var allowed: [String]

        init(allowed: [String]) {
            self.allowed = allowed
        }

        func check(_ item: NetworkCheckpoint) -> [String] {
            if allowed.count == 0 {
                return []
            }
            if !allowed.contains(Kit.Text.normalize(item.code)) {
                return ["code \(item.code) is duplicated"]
            }
            return []
        }
    }

    final class NetworkCheckpointRequiredNameRule: NetworkCheckpointRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: NetworkCheckpoint) -> [String] {
            if item.name.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class NetworkCheckpointCodeLengthRule: NetworkCheckpointRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: NetworkCheckpoint) -> [String] {
            let size = item.code.count
            if size > maxLength {
                return ["code is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    /// Runs every rule of a network checkpoint.
    final class NetworkCheckpointValidator {
        var rules: [any NetworkCheckpointRule]

        init(rules: [any NetworkCheckpointRule]) {
            self.rules = rules
        }

        func validate(_ item: NetworkCheckpoint) -> [String] {
            var problems: [String] = []
            for rule in rules {
                for problem in rule.check(item) {
                    problems.append(problem)
                }
            }
            return problems
        }

        func requireValid(_ item: NetworkCheckpoint) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.label()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [NetworkCheckpoint]) -> [String: [String]] {
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

    static func defaultNetworkCheckpointValidator() -> NetworkCheckpointValidator {
        return NetworkCheckpointValidator(
            rules: [
                NetworkCheckpointRequiredCodeRule(message: "network checkpoint needs a value"),
                NetworkCheckpointRequiredAllergyRule(message: "network checkpoint needs an entry"),
                NetworkCheckpointAllowedCodeRule(allowed: ["batched", "manual"]),
                NetworkCheckpointRequiredNameRule(message: "network checkpoint needs an entry"),
                NetworkCheckpointCodeLengthRule(maxLength: 64),
            ]
        )
    }
}
