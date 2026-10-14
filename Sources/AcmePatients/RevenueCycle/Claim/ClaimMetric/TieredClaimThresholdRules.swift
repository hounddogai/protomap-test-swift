import AcmePlatform
import Foundation

extension RevenueCycle {
    /// A rule a tiered claim threshold must pass. Check returns its problems, or none.
    protocol TieredClaimThresholdRule {
        func check(_ item: TieredClaimThreshold) -> [String]
    }

    final class TieredClaimThresholdRequiredProcedureCodeRule: TieredClaimThresholdRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: TieredClaimThreshold) -> [String] {
            if item.procedureCode.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class TieredClaimThresholdCodePrefixRule: TieredClaimThresholdRule {
        var prefix: String

        init(prefix: String) {
            self.prefix = prefix
        }

        func check(_ item: TieredClaimThreshold) -> [String] {
            if !item.code.uppercased().hasPrefix(prefix.uppercased()) {
                return ["code must start with \(prefix)"]
            }
            return []
        }
    }

    final class TieredClaimThresholdSummaryLengthRule: TieredClaimThresholdRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: TieredClaimThreshold) -> [String] {
            let size = item.summary.count
            if size > maxLength {
                return ["summary is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class TieredClaimThresholdRequiredCodeRule: TieredClaimThresholdRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: TieredClaimThreshold) -> [String] {
            if item.code.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    /// Runs every rule of a tiered claim threshold.
    final class TieredClaimThresholdValidator {
        var rules: [any TieredClaimThresholdRule]

        init(rules: [any TieredClaimThresholdRule]) {
            self.rules = rules
        }

        func validate(_ item: TieredClaimThreshold) -> [String] {
            var problems: [String] = []
            for rule in rules {
                for problem in rule.check(item) {
                    problems.append(problem)
                }
            }
            return problems
        }

        func requireValid(_ item: TieredClaimThreshold) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.displayLabel()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [TieredClaimThreshold]) -> [String: [String]] {
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

    static func defaultTieredClaimThresholdValidator() -> TieredClaimThresholdValidator {
        return TieredClaimThresholdValidator(
            rules: [
                TieredClaimThresholdRequiredProcedureCodeRule(message: "tiered claim threshold needs a value"),
                TieredClaimThresholdCodePrefixRule(prefix: "ACM"),
                TieredClaimThresholdSummaryLengthRule(maxLength: 32),
                TieredClaimThresholdRequiredCodeRule(message: "tiered claim threshold needs this field"),
            ]
        )
    }
}
