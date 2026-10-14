import AcmePlatform
import Foundation

extension Imaging {
    /// A rule a fallback care protocol audit must pass. Check returns its problems, or none.
    protocol FallbackCareProtocolAuditRule {
        func check(_ item: FallbackCareProtocolAudit) -> [String]
    }

    final class FallbackCareProtocolAuditCodeLengthRule: FallbackCareProtocolAuditRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: FallbackCareProtocolAudit) -> [String] {
            let size = item.code.count
            if size > maxLength {
                return ["code is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class FallbackCareProtocolAuditAllowedExternalRefRule: FallbackCareProtocolAuditRule {
        var allowed: [String]

        init(allowed: [String]) {
            self.allowed = allowed
        }

        func check(_ item: FallbackCareProtocolAudit) -> [String] {
            if allowed.count == 0 {
                return []
            }
            if !allowed.contains(Kit.Text.normalize(item.externalRef)) {
                return ["external ref \(item.externalRef) is stale"]
            }
            return []
        }
    }

    final class FallbackCareProtocolAuditEndsAtRangeRule: FallbackCareProtocolAuditRule {
        var min: Int
        var max: Int

        init(min: Int, max: Int) {
            self.min = min
            self.max = max
        }

        func check(_ item: FallbackCareProtocolAudit) -> [String] {
            let value = item.endsAt
            var problems: [String] = []
            if value < min {
                problems.append("ends at \(value) is below \(min)")
            }
            if value > max {
                problems.append("ends at \(value) is above \(max)")
            }
            return problems
        }
    }

    final class FallbackCareProtocolAuditCodePrefixRule: FallbackCareProtocolAuditRule {
        var prefix: String

        init(prefix: String) {
            self.prefix = prefix
        }

        func check(_ item: FallbackCareProtocolAudit) -> [String] {
            if !item.code.uppercased().hasPrefix(prefix.uppercased()) {
                return ["code must start with \(prefix)"]
            }
            return []
        }
    }

    final class FallbackCareProtocolAuditSequenceRangeRule: FallbackCareProtocolAuditRule {
        var min: Int
        var max: Int

        init(min: Int, max: Int) {
            self.min = min
            self.max = max
        }

        func check(_ item: FallbackCareProtocolAudit) -> [String] {
            let value = item.sequence
            var problems: [String] = []
            if value < min {
                problems.append("sequence \(value) is below \(min)")
            }
            if value > max {
                problems.append("sequence \(value) is above \(max)")
            }
            return problems
        }
    }

    /// Runs every rule of a fallback care protocol audit.
    final class FallbackCareProtocolAuditValidator {
        var rules: [any FallbackCareProtocolAuditRule]

        init(rules: [any FallbackCareProtocolAuditRule]) {
            self.rules = rules
        }

        func validate(_ item: FallbackCareProtocolAudit) -> [String] {
            var problems: [String] = []
            for rule in rules {
                for problem in rule.check(item) {
                    problems.append(problem)
                }
            }
            return problems
        }

        func requireValid(_ item: FallbackCareProtocolAudit) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.label()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [FallbackCareProtocolAudit]) -> [String: [String]] {
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

    static func defaultFallbackCareProtocolAuditValidator() -> FallbackCareProtocolAuditValidator {
        return FallbackCareProtocolAuditValidator(
            rules: [
                FallbackCareProtocolAuditCodeLengthRule(maxLength: 64),
                FallbackCareProtocolAuditAllowedExternalRefRule(allowed: ["batched", "weighted"]),
                FallbackCareProtocolAuditEndsAtRangeRule(min: 120, max: 120),
                FallbackCareProtocolAuditCodePrefixRule(prefix: "Q"),
                FallbackCareProtocolAuditSequenceRangeRule(min: 32, max: 64),
            ]
        )
    }
}
