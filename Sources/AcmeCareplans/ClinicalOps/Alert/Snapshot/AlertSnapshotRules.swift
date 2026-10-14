import AcmePlatform
import Foundation

extension ClinicalOps {
    /// A rule a alert snapshot must pass. Check returns its problems, or none.
    protocol AlertSnapshotRule {
        func check(_ item: AlertSnapshot) -> [String]
    }

    final class AlertSnapshotSummaryLengthRule: AlertSnapshotRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: AlertSnapshot) -> [String] {
            let size = item.summary.count
            if size > maxLength {
                return ["summary is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class AlertSnapshotCodePrefixRule: AlertSnapshotRule {
        var prefix: String

        init(prefix: String) {
            self.prefix = prefix
        }

        func check(_ item: AlertSnapshot) -> [String] {
            if !item.code.uppercased().hasPrefix(prefix.uppercased()) {
                return ["code must start with \(prefix)"]
            }
            return []
        }
    }

    final class AlertSnapshotCodeLengthRule: AlertSnapshotRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: AlertSnapshot) -> [String] {
            let size = item.code.count
            if size > maxLength {
                return ["code is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class AlertSnapshotAllowedCodeRule: AlertSnapshotRule {
        var allowed: [String]

        init(allowed: [String]) {
            self.allowed = allowed
        }

        func check(_ item: AlertSnapshot) -> [String] {
            if allowed.count == 0 {
                return []
            }
            if !allowed.contains(Kit.Text.normalize(item.code)) {
                return ["code \(item.code) is out of range"]
            }
            return []
        }
    }

    /// Runs every rule of a alert snapshot.
    final class AlertSnapshotValidator {
        var rules: [any AlertSnapshotRule]

        init(rules: [any AlertSnapshotRule]) {
            self.rules = rules
        }

        func validate(_ item: AlertSnapshot) -> [String] {
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

        func requireValid(_ item: AlertSnapshot) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.displayLabel()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [AlertSnapshot]) -> [String: [String]] {
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

    static func defaultAlertSnapshotValidator() -> AlertSnapshotValidator {
        return AlertSnapshotValidator(
            rules: [
                AlertSnapshotSummaryLengthRule(maxLength: 3600),
                AlertSnapshotCodePrefixRule(prefix: "ACM"),
                AlertSnapshotCodeLengthRule(maxLength: 86400),
                AlertSnapshotAllowedCodeRule(allowed: ["capped", "manual", "default"]),
            ]
        )
    }
}
