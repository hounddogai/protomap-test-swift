import AcmePlatform
import Foundation

extension BedManagement {
    /// A rule a legacy census metric must pass. Check returns its problems, or none.
    protocol LegacyCensusMetricRule {
        func check(_ item: LegacyCensusMetric) -> [String]
    }

    final class LegacyCensusMetricNotesLengthRule: LegacyCensusMetricRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: LegacyCensusMetric) -> [String] {
            let size = item.notes.count
            if size > maxLength {
                return ["notes is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class LegacyCensusMetricCodePrefixRule: LegacyCensusMetricRule {
        var prefix: String

        init(prefix: String) {
            self.prefix = prefix
        }

        func check(_ item: LegacyCensusMetric) -> [String] {
            if !item.code.uppercased().hasPrefix(prefix.uppercased()) {
                return ["code must start with \(prefix)"]
            }
            return []
        }
    }

    final class LegacyCensusMetricCodeLengthRule: LegacyCensusMetricRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: LegacyCensusMetric) -> [String] {
            let size = item.code.count
            if size > maxLength {
                return ["code is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    /// Runs every rule of a legacy census metric.
    final class LegacyCensusMetricValidator {
        var rules: [any LegacyCensusMetricRule]

        init(rules: [any LegacyCensusMetricRule]) {
            self.rules = rules
        }

        func validate(_ item: LegacyCensusMetric) -> [String] {
            var problems: [String] = []
            for rule in rules {
                for problem in rule.check(item) {
                    problems.append(problem)
                }
            }
            return problems
        }

        func requireValid(_ item: LegacyCensusMetric) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.label()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [LegacyCensusMetric]) -> [String: [String]] {
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

    static func defaultLegacyCensusMetricValidator() -> LegacyCensusMetricValidator {
        return LegacyCensusMetricValidator(
            rules: [
                LegacyCensusMetricNotesLengthRule(maxLength: 86400),
                LegacyCensusMetricCodePrefixRule(prefix: "Q"),
                LegacyCensusMetricCodeLengthRule(maxLength: 255),
            ]
        )
    }
}
