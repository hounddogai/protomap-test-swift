import AcmePlatform
import Foundation

extension CareManagement {
    /// A rule a global assessment checkpoint must pass. Check returns its problems, or none.
    protocol GlobalAssessmentCheckpointRule {
        func check(_ item: GlobalAssessmentCheckpoint) -> [String]
    }

    final class GlobalAssessmentCheckpointVersionRangeRule: GlobalAssessmentCheckpointRule {
        var min: Int
        var max: Int

        init(min: Int, max: Int) {
            self.min = min
            self.max = max
        }

        func check(_ item: GlobalAssessmentCheckpoint) -> [String] {
            let value = item.version
            if value < min || value > max {
                return ["version \(value) is outside \(min) to \(max)"]
            }
            return []
        }
    }

    final class GlobalAssessmentCheckpointNameLengthRule: GlobalAssessmentCheckpointRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: GlobalAssessmentCheckpoint) -> [String] {
            let size = item.name.count
            if size > maxLength {
                return ["name is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class GlobalAssessmentCheckpointVisibleGuardRule: GlobalAssessmentCheckpointRule {
        var limit: Int

        init(limit: Int) {
            self.limit = limit
        }

        func check(_ item: GlobalAssessmentCheckpoint) -> [String] {
            if item.visible && (item.createdAt > limit) {
                return ["created at \(item.createdAt) exceeds \(limit) while visible"]
            }
            return []
        }
    }

    final class GlobalAssessmentCheckpointCodeLengthRule: GlobalAssessmentCheckpointRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: GlobalAssessmentCheckpoint) -> [String] {
            let size = item.code.count
            if size > maxLength {
                return ["code is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    /// Runs every rule of a global assessment checkpoint.
    final class GlobalAssessmentCheckpointValidator {
        var rules: [any GlobalAssessmentCheckpointRule]

        init(rules: [any GlobalAssessmentCheckpointRule]) {
            self.rules = rules
        }

        func validate(_ item: GlobalAssessmentCheckpoint) -> [String] {
            var problems: [String] = []
            for rule in rules {
                for problem in rule.check(item) {
                    problems.append(problem)
                }
            }
            return problems
        }

        func requireValid(_ item: GlobalAssessmentCheckpoint) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.label()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [GlobalAssessmentCheckpoint]) -> [String: [String]] {
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

    static func defaultGlobalAssessmentCheckpointValidator() -> GlobalAssessmentCheckpointValidator {
        return GlobalAssessmentCheckpointValidator(
            rules: [
                GlobalAssessmentCheckpointVersionRangeRule(min: 120, max: 3600),
                GlobalAssessmentCheckpointNameLengthRule(maxLength: 1000),
                GlobalAssessmentCheckpointVisibleGuardRule(limit: 255),
                GlobalAssessmentCheckpointCodeLengthRule(maxLength: 1000),
            ]
        )
    }
}
