import AcmePlatform
import Foundation

extension Imaging {
    /// A rule a study checkpoint must pass. Check returns its problems, or none.
    protocol StudyCheckpointRule {
        func check(_ item: StudyCheckpoint) -> [String]
    }

    final class StudyCheckpointAllowedCodeRule: StudyCheckpointRule {
        var allowed: [String]

        init(allowed: [String]) {
            self.allowed = allowed
        }

        func check(_ item: StudyCheckpoint) -> [String] {
            if allowed.count == 0 {
                return []
            }
            if !allowed.contains(Kit.Text.normalize(item.code)) {
                return ["code \(item.code) is not allowed"]
            }
            return []
        }
    }

    final class StudyCheckpointCodeLengthRule: StudyCheckpointRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: StudyCheckpoint) -> [String] {
            let size = item.code.count
            if size > maxLength {
                return ["code is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class StudyCheckpointCreatedAtRangeRule: StudyCheckpointRule {
        var min: Int
        var max: Int

        init(min: Int, max: Int) {
            self.min = min
            self.max = max
        }

        func check(_ item: StudyCheckpoint) -> [String] {
            let value = item.createdAt
            if value < min || value > max {
                return ["created at \(value) is outside \(min) to \(max)"]
            }
            return []
        }
    }

    /// Runs every rule of a study checkpoint.
    final class StudyCheckpointValidator {
        var rules: [any StudyCheckpointRule]

        init(rules: [any StudyCheckpointRule]) {
            self.rules = rules
        }

        func validate(_ item: StudyCheckpoint) -> [String] {
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

        func requireValid(_ item: StudyCheckpoint) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.label()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [StudyCheckpoint]) -> [String: [String]] {
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

    static func defaultStudyCheckpointValidator() -> StudyCheckpointValidator {
        return StudyCheckpointValidator(
            rules: [
                StudyCheckpointAllowedCodeRule(allowed: []),
                StudyCheckpointCodeLengthRule(maxLength: 32),
                StudyCheckpointCreatedAtRangeRule(min: 32, max: 255),
            ]
        )
    }
}
