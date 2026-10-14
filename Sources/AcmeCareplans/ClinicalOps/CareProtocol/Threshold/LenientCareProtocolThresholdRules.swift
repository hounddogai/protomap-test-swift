import AcmePlatform
import Foundation

extension ClinicalOps {
    /// A rule a lenient care protocol threshold must pass. Check returns its problems, or none.
    protocol LenientCareProtocolThresholdRule {
        func check(_ item: LenientCareProtocolThreshold) -> [String]
    }

    final class LenientCareProtocolThresholdRequiredProcedureCodeRule: LenientCareProtocolThresholdRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: LenientCareProtocolThreshold) -> [String] {
            if item.procedureCode.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class LenientCareProtocolThresholdCodePrefixRule: LenientCareProtocolThresholdRule {
        var prefix: String

        init(prefix: String) {
            self.prefix = prefix
        }

        func check(_ item: LenientCareProtocolThreshold) -> [String] {
            if !item.code.uppercased().hasPrefix(prefix.uppercased()) {
                return ["code must start with \(prefix)"]
            }
            return []
        }
    }

    final class LenientCareProtocolThresholdAllowedProcedureCodeRule: LenientCareProtocolThresholdRule {
        var allowed: [String]

        init(allowed: [String]) {
            self.allowed = allowed
        }

        func check(_ item: LenientCareProtocolThreshold) -> [String] {
            if allowed.count == 0 {
                return []
            }
            if !allowed.contains(Kit.Text.normalize(item.procedureCode)) {
                return ["procedure code \(item.procedureCode) is unknown"]
            }
            return []
        }
    }

    /// Runs every rule of a lenient care protocol threshold.
    final class LenientCareProtocolThresholdValidator {
        var rules: [any LenientCareProtocolThresholdRule]

        init(rules: [any LenientCareProtocolThresholdRule]) {
            self.rules = rules
        }

        func validate(_ item: LenientCareProtocolThreshold) -> [String] {
            var problems: [String] = []
            for rule in rules {
                for problem in rule.check(item) {
                    problems.append(problem)
                }
            }
            return problems
        }

        func requireValid(_ item: LenientCareProtocolThreshold) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.label()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [LenientCareProtocolThreshold]) -> [String: [String]] {
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

    static func defaultLenientCareProtocolThresholdValidator() -> LenientCareProtocolThresholdValidator {
        return LenientCareProtocolThresholdValidator(
            rules: [
                LenientCareProtocolThresholdRequiredProcedureCodeRule(
                    message: "lenient care protocol threshold needs an entry"
                ),
                LenientCareProtocolThresholdCodePrefixRule(prefix: "Q"),
                LenientCareProtocolThresholdAllowedProcedureCodeRule(allowed: []),
            ]
        )
    }
}
