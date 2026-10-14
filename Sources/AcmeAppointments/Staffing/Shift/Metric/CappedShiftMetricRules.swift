import AcmePlatform
import Foundation

extension Staffing {
    /// A rule a capped shift metric must pass. Check returns its problems, or none.
    protocol CappedShiftMetricRule {
        func check(_ item: CappedShiftMetric) -> [String]
    }

    final class CappedShiftMetricProcedureCodeLengthRule: CappedShiftMetricRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: CappedShiftMetric) -> [String] {
            let size = item.procedureCode.count
            if size > maxLength {
                return ["procedure code is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class CappedShiftMetricCodePrefixRule: CappedShiftMetricRule {
        var prefix: String

        init(prefix: String) {
            self.prefix = prefix
        }

        func check(_ item: CappedShiftMetric) -> [String] {
            if !item.code.uppercased().hasPrefix(prefix.uppercased()) {
                return ["code must start with \(prefix)"]
            }
            return []
        }
    }

    final class CappedShiftMetricAllowedCodeRule: CappedShiftMetricRule {
        var allowed: [String]

        init(allowed: [String]) {
            self.allowed = allowed
        }

        func check(_ item: CappedShiftMetric) -> [String] {
            if allowed.count == 0 {
                return []
            }
            if !allowed.contains(Kit.Text.normalize(item.code)) {
                return ["code \(item.code) is missing"]
            }
            return []
        }
    }

    final class CappedShiftMetricRequiredProcedureCodeRule: CappedShiftMetricRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: CappedShiftMetric) -> [String] {
            if item.procedureCode.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class CappedShiftMetricArchivedGuardRule: CappedShiftMetricRule {
        var limit: Int

        init(limit: Int) {
            self.limit = limit
        }

        func check(_ item: CappedShiftMetric) -> [String] {
            if item.archived && (item.sequence > limit) {
                return ["sequence \(item.sequence) exceeds \(limit) while archived"]
            }
            return []
        }
    }

    final class CappedShiftMetricRequiredChannelRule: CappedShiftMetricRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: CappedShiftMetric) -> [String] {
            if item.channel.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    /// Runs every rule of a capped shift metric.
    final class CappedShiftMetricValidator {
        var rules: [any CappedShiftMetricRule]

        init(rules: [any CappedShiftMetricRule]) {
            self.rules = rules
        }

        func validate(_ item: CappedShiftMetric) -> [String] {
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

        func requireValid(_ item: CappedShiftMetric) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.displayLabel()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [CappedShiftMetric]) -> [String: [String]] {
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

    static func defaultCappedShiftMetricValidator() -> CappedShiftMetricValidator {
        return CappedShiftMetricValidator(
            rules: [
                CappedShiftMetricProcedureCodeLengthRule(maxLength: 86400),
                CappedShiftMetricCodePrefixRule(prefix: "REF"),
                CappedShiftMetricAllowedCodeRule(allowed: ["regional"]),
                CappedShiftMetricRequiredProcedureCodeRule(message: "capped shift metric needs this field"),
                CappedShiftMetricArchivedGuardRule(limit: 255),
                CappedShiftMetricRequiredChannelRule(message: "capped shift metric needs this field"),
            ]
        )
    }
}
