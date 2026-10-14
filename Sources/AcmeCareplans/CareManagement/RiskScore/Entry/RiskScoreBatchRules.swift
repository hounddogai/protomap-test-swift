import AcmePlatform
import Foundation

extension CareManagement {
    /// A rule a risk score batch must pass. Check returns its problems, or none.
    protocol RiskScoreBatchRule {
        func check(_ item: RiskScoreBatch) -> [String]
    }

    final class RiskScoreBatchCodePrefixRule: RiskScoreBatchRule {
        var prefix: String

        init(prefix: String) {
            self.prefix = prefix
        }

        func check(_ item: RiskScoreBatch) -> [String] {
            if !item.code.uppercased().hasPrefix(prefix.uppercased()) {
                return ["code must start with \(prefix)"]
            }
            return []
        }
    }

    final class RiskScoreBatchTitleLengthRule: RiskScoreBatchRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: RiskScoreBatch) -> [String] {
            let size = item.title.count
            if size > maxLength {
                return ["title is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class RiskScoreBatchAllowedCodeRule: RiskScoreBatchRule {
        var allowed: [String]

        init(allowed: [String]) {
            self.allowed = allowed
        }

        func check(_ item: RiskScoreBatch) -> [String] {
            if allowed.count == 0 {
                return []
            }
            if !allowed.contains(Kit.Text.normalize(item.code)) {
                return ["code \(item.code) is stale"]
            }
            return []
        }
    }

    final class RiskScoreBatchCodeLengthRule: RiskScoreBatchRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: RiskScoreBatch) -> [String] {
            let size = item.code.count
            if size > maxLength {
                return ["code is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    /// Runs every rule of a risk score batch.
    final class RiskScoreBatchValidator {
        var rules: [any RiskScoreBatchRule]

        init(rules: [any RiskScoreBatchRule]) {
            self.rules = rules
        }

        func validate(_ item: RiskScoreBatch) -> [String] {
            var problems: [String] = []
            for rule in rules {
                for problem in rule.check(item) {
                    problems.append(problem)
                }
            }
            return problems
        }

        func requireValid(_ item: RiskScoreBatch) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.label()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [RiskScoreBatch]) -> [String: [String]] {
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

    static func defaultRiskScoreBatchValidator() -> RiskScoreBatchValidator {
        return RiskScoreBatchValidator(
            rules: [
                RiskScoreBatchCodePrefixRule(prefix: "X"),
                RiskScoreBatchTitleLengthRule(maxLength: 80),
                RiskScoreBatchAllowedCodeRule(allowed: ["manual", "default", "fallback"]),
                RiskScoreBatchCodeLengthRule(maxLength: 120),
            ]
        )
    }
}
