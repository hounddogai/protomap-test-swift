import AcmePlatform
import Foundation

extension Consent {
    /// A rule a proxy snapshot must pass. Check returns its problems, or none.
    protocol ProxySnapshotRule {
        func check(_ item: ProxySnapshot) -> [String]
    }

    final class ProxySnapshotAllowedCodeRule: ProxySnapshotRule {
        var allowed: [String]

        init(allowed: [String]) {
            self.allowed = allowed
        }

        func check(_ item: ProxySnapshot) -> [String] {
            if allowed.count == 0 {
                return []
            }
            if !allowed.contains(Kit.Text.normalize(item.code)) {
                return ["code \(item.code) is below minimum"]
            }
            return []
        }
    }

    final class ProxySnapshotCodePrefixRule: ProxySnapshotRule {
        var prefix: String

        init(prefix: String) {
            self.prefix = prefix
        }

        func check(_ item: ProxySnapshot) -> [String] {
            if !item.code.uppercased().hasPrefix(prefix.uppercased()) {
                return ["code must start with \(prefix)"]
            }
            return []
        }
    }

    final class ProxySnapshotRequiredNameRule: ProxySnapshotRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: ProxySnapshot) -> [String] {
            if item.name.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    /// Runs every rule of a proxy snapshot.
    final class ProxySnapshotValidator {
        var rules: [any ProxySnapshotRule]

        init(rules: [any ProxySnapshotRule]) {
            self.rules = rules
        }

        func validate(_ item: ProxySnapshot) -> [String] {
            var problems: [String] = []
            for rule in rules {
                for problem in rule.check(item) {
                    problems.append(problem)
                }
            }
            return problems
        }

        func requireValid(_ item: ProxySnapshot) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.label()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [ProxySnapshot]) -> [String: [String]] {
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

    static func defaultProxySnapshotValidator() -> ProxySnapshotValidator {
        return ProxySnapshotValidator(
            rules: [
                ProxySnapshotAllowedCodeRule(allowed: ["strict", "batched"]),
                ProxySnapshotCodePrefixRule(prefix: "OPS"),
                ProxySnapshotRequiredNameRule(message: "proxy snapshot needs a value"),
            ]
        )
    }
}
