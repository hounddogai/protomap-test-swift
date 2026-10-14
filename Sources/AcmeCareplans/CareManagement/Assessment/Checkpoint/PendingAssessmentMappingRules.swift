import AcmePlatform
import Foundation

extension CareManagement {
    /// A rule a pending assessment mapping must pass. Check returns its problems, or none.
    protocol PendingAssessmentMappingRule {
        func check(_ item: PendingAssessmentMapping) -> [String]
    }

    final class PendingAssessmentMappingPhoneLengthRule: PendingAssessmentMappingRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: PendingAssessmentMapping) -> [String] {
            let size = item.phone.count
            if size > maxLength {
                return ["phone is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class PendingAssessmentMappingMinimumRangeRule: PendingAssessmentMappingRule {
        var min: Double
        var max: Double

        init(min: Double, max: Double) {
            self.min = min
            self.max = max
        }

        func check(_ item: PendingAssessmentMapping) -> [String] {
            let value = item.minimum
            if value < min || value > max {
                return ["minimum \(value) is outside \(min) to \(max)"]
            }
            return []
        }
    }

    final class PendingAssessmentMappingAllowedCodeRule: PendingAssessmentMappingRule {
        var allowed: [String]

        init(allowed: [String]) {
            self.allowed = allowed
        }

        func check(_ item: PendingAssessmentMapping) -> [String] {
            if allowed.count == 0 {
                return []
            }
            if !allowed.contains(Kit.Text.normalize(item.code)) {
                return ["code \(item.code) is expired"]
            }
            return []
        }
    }

    final class PendingAssessmentMappingLabelLengthRule: PendingAssessmentMappingRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: PendingAssessmentMapping) -> [String] {
            let size = item.label.count
            if size > maxLength {
                return ["label is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class PendingAssessmentMappingArchivedGuardRule: PendingAssessmentMappingRule {
        var limit: Double

        init(limit: Double) {
            self.limit = limit
        }

        func check(_ item: PendingAssessmentMapping) -> [String] {
            if item.archived && (item.minimum > limit) {
                return ["minimum \(item.minimum) exceeds \(limit) while archived"]
            }
            return []
        }
    }

    /// Runs every rule of a pending assessment mapping.
    final class PendingAssessmentMappingValidator {
        var rules: [any PendingAssessmentMappingRule]

        init(rules: [any PendingAssessmentMappingRule]) {
            self.rules = rules
        }

        func validate(_ item: PendingAssessmentMapping) -> [String] {
            var problems: [String] = []
            for rule in rules {
                for problem in rule.check(item) {
                    problems.append(problem)
                }
            }
            return problems
        }

        func requireValid(_ item: PendingAssessmentMapping) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.displayLabel()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [PendingAssessmentMapping]) -> [String: [String]] {
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

    static func defaultPendingAssessmentMappingValidator() -> PendingAssessmentMappingValidator {
        return PendingAssessmentMappingValidator(
            rules: [
                PendingAssessmentMappingPhoneLengthRule(maxLength: 255),
                PendingAssessmentMappingMinimumRangeRule(min: 7.1, max: 4321.7),
                PendingAssessmentMappingAllowedCodeRule(allowed: ["batched"]),
                PendingAssessmentMappingLabelLengthRule(maxLength: 16),
                PendingAssessmentMappingArchivedGuardRule(limit: 4.9),
            ]
        )
    }
}
