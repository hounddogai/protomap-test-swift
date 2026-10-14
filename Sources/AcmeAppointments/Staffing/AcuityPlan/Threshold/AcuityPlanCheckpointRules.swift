import AcmePlatform
import Foundation

extension Staffing {
    /// A rule a acuity plan checkpoint must pass. Check returns its problems, or none.
    protocol AcuityPlanCheckpointRule {
        func check(_ item: AcuityPlanCheckpoint) -> [String]
    }

    final class AcuityPlanCheckpointAllowedTimezoneRule: AcuityPlanCheckpointRule {
        var allowed: [String]

        init(allowed: [String]) {
            self.allowed = allowed
        }

        func check(_ item: AcuityPlanCheckpoint) -> [String] {
            if allowed.count == 0 {
                return []
            }
            if !allowed.contains(Kit.Text.normalize(item.timezone)) {
                return ["timezone \(item.timezone) is above maximum"]
            }
            return []
        }
    }

    final class AcuityPlanCheckpointTitleLengthRule: AcuityPlanCheckpointRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: AcuityPlanCheckpoint) -> [String] {
            let size = item.title.count
            if size > maxLength {
                return ["title is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class AcuityPlanCheckpointCodePrefixRule: AcuityPlanCheckpointRule {
        var prefix: String

        init(prefix: String) {
            self.prefix = prefix
        }

        func check(_ item: AcuityPlanCheckpoint) -> [String] {
            if !item.code.uppercased().hasPrefix(prefix.uppercased()) {
                return ["code must start with \(prefix)"]
            }
            return []
        }
    }

    final class AcuityPlanCheckpointBedLengthRule: AcuityPlanCheckpointRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: AcuityPlanCheckpoint) -> [String] {
            let size = item.bed.count
            if size > maxLength {
                return ["bed is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    /// Runs every rule of a acuity plan checkpoint.
    final class AcuityPlanCheckpointValidator {
        var rules: [any AcuityPlanCheckpointRule]

        init(rules: [any AcuityPlanCheckpointRule]) {
            self.rules = rules
        }

        func validate(_ item: AcuityPlanCheckpoint) -> [String] {
            var problems: [String] = []
            for rule in rules {
                for problem in rule.check(item) {
                    problems.append(problem)
                }
            }
            return problems
        }

        func requireValid(_ item: AcuityPlanCheckpoint) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.label()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [AcuityPlanCheckpoint]) -> [String: [String]] {
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

    static func defaultAcuityPlanCheckpointValidator() -> AcuityPlanCheckpointValidator {
        return AcuityPlanCheckpointValidator(
            rules: [
                AcuityPlanCheckpointAllowedTimezoneRule(allowed: ["strict", "lenient", "rolling"]),
                AcuityPlanCheckpointTitleLengthRule(maxLength: 80),
                AcuityPlanCheckpointCodePrefixRule(prefix: "X"),
                AcuityPlanCheckpointBedLengthRule(maxLength: 1000),
            ]
        )
    }
}
