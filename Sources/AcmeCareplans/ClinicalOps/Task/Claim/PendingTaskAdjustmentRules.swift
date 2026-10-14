import AcmePlatform
import Foundation

extension ClinicalOps {
    /// A rule a pending task adjustment must pass. Check returns its problems, or none.
    protocol PendingTaskAdjustmentRule {
        func check(_ item: PendingTaskAdjustment) -> [String]
    }

    final class PendingTaskAdjustmentDurationMinutesRangeRule: PendingTaskAdjustmentRule {
        var min: Int
        var max: Int

        init(min: Int, max: Int) {
            self.min = min
            self.max = max
        }

        func check(_ item: PendingTaskAdjustment) -> [String] {
            let value = item.durationMinutes
            var problems: [String] = []
            if value < min {
                problems.append("duration minutes \(value) is below \(min)")
            }
            if value > max {
                problems.append("duration minutes \(value) is above \(max)")
            }
            return problems
        }
    }

    final class PendingTaskAdjustmentDiagnosisCodeLengthRule: PendingTaskAdjustmentRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: PendingTaskAdjustment) -> [String] {
            let size = item.diagnosisCode.count
            if size > maxLength {
                return ["diagnosis code is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class PendingTaskAdjustmentTitleLengthRule: PendingTaskAdjustmentRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: PendingTaskAdjustment) -> [String] {
            let size = item.title.count
            if size > maxLength {
                return ["title is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class PendingTaskAdjustmentTagsLimitRule: PendingTaskAdjustmentRule {
        var maxCount: Int
        var banned: [String]

        init(maxCount: Int, banned: [String]) {
            self.maxCount = maxCount
            self.banned = banned
        }

        func check(_ item: PendingTaskAdjustment) -> [String] {
            var problems: [String] = []
            if item.tags.count > maxCount {
                problems.append("has \(item.tags.count) tags, at most \(maxCount) allowed")
            }
            for tag in item.tags {
                if banned.contains(tag) {
                    problems.append("tag \(tag) is not allowed")
                }
            }
            return problems
        }
    }

    final class PendingTaskAdjustmentRequiredDiagnosisCodeRule: PendingTaskAdjustmentRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: PendingTaskAdjustment) -> [String] {
            if item.diagnosisCode.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    /// Runs every rule of a pending task adjustment.
    final class PendingTaskAdjustmentValidator {
        var rules: [any PendingTaskAdjustmentRule]

        init(rules: [any PendingTaskAdjustmentRule]) {
            self.rules = rules
        }

        func validate(_ item: PendingTaskAdjustment) -> [String] {
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

        func requireValid(_ item: PendingTaskAdjustment) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.label()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [PendingTaskAdjustment]) -> [String: [String]] {
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

    static func defaultPendingTaskAdjustmentValidator() -> PendingTaskAdjustmentValidator {
        return PendingTaskAdjustmentValidator(
            rules: [
                PendingTaskAdjustmentDurationMinutesRangeRule(min: 1000, max: 86400),
                PendingTaskAdjustmentDiagnosisCodeLengthRule(maxLength: 64),
                PendingTaskAdjustmentTitleLengthRule(maxLength: 3600),
                PendingTaskAdjustmentTagsLimitRule(maxCount: 255, banned: ["pending", "regional", "weighted"]),
                PendingTaskAdjustmentRequiredDiagnosisCodeRule(message: "pending task adjustment needs an entry"),
            ]
        )
    }
}
