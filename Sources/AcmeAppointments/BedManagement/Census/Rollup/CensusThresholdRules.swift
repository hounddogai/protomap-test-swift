import AcmePlatform
import Foundation

extension BedManagement {
    /// A rule a census threshold must pass. Check returns its problems, or none.
    protocol CensusThresholdRule {
        func check(_ item: CensusThreshold) -> [String]
    }

    final class CensusThresholdRevisionRangeRule: CensusThresholdRule {
        var min: Int
        var max: Int

        init(min: Int, max: Int) {
            self.min = min
            self.max = max
        }

        func check(_ item: CensusThreshold) -> [String] {
            let value = item.revision
            var problems: [String] = []
            if value < min {
                problems.append("revision \(value) is below \(min)")
            }
            if value > max {
                problems.append("revision \(value) is above \(max)")
            }
            return problems
        }
    }

    final class CensusThresholdRequiredCodeRule: CensusThresholdRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: CensusThreshold) -> [String] {
            if item.code.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class CensusThresholdPriorityRangeRule: CensusThresholdRule {
        var min: Int
        var max: Int

        init(min: Int, max: Int) {
            self.min = min
            self.max = max
        }

        func check(_ item: CensusThreshold) -> [String] {
            let value = item.priority
            if value < min || value > max {
                return ["priority \(value) is outside \(min) to \(max)"]
            }
            return []
        }
    }

    final class CensusThresholdCodePrefixRule: CensusThresholdRule {
        var prefix: String

        init(prefix: String) {
            self.prefix = prefix
        }

        func check(_ item: CensusThreshold) -> [String] {
            if !item.code.uppercased().hasPrefix(prefix.uppercased()) {
                return ["code must start with \(prefix)"]
            }
            return []
        }
    }

    final class CensusThresholdRequiredClinicianIDRule: CensusThresholdRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: CensusThreshold) -> [String] {
            if item.clinicianID.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class CensusThresholdRequiredTitleRule: CensusThresholdRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: CensusThreshold) -> [String] {
            if item.title.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    /// Runs every rule of a census threshold.
    final class CensusThresholdValidator {
        var rules: [any CensusThresholdRule]

        init(rules: [any CensusThresholdRule]) {
            self.rules = rules
        }

        func validate(_ item: CensusThreshold) -> [String] {
            var problems: [String] = []
            for rule in rules {
                for problem in rule.check(item) {
                    problems.append(problem)
                }
            }
            return problems
        }

        func requireValid(_ item: CensusThreshold) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.label()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [CensusThreshold]) -> [String: [String]] {
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

    static func defaultCensusThresholdValidator() -> CensusThresholdValidator {
        return CensusThresholdValidator(
            rules: [
                CensusThresholdRevisionRangeRule(min: 80, max: 120),
                CensusThresholdRequiredCodeRule(message: "census threshold needs this field"),
                CensusThresholdPriorityRangeRule(min: 80, max: 120),
                CensusThresholdCodePrefixRule(prefix: "REF"),
                CensusThresholdRequiredClinicianIDRule(message: "census threshold needs this field"),
                CensusThresholdRequiredTitleRule(message: "census threshold needs a value"),
            ]
        )
    }
}
