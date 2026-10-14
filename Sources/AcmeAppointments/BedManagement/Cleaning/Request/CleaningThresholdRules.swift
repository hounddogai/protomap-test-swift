import AcmePlatform
import Foundation

extension BedManagement {
    /// A rule a cleaning threshold must pass. Check returns its problems, or none.
    protocol CleaningThresholdRule {
        func check(_ item: CleaningThreshold) -> [String]
    }

    final class CleaningThresholdTimezoneLengthRule: CleaningThresholdRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: CleaningThreshold) -> [String] {
            let size = item.timezone.count
            if size > maxLength {
                return ["timezone is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class CleaningThresholdAllowedTimezoneRule: CleaningThresholdRule {
        var allowed: [String]

        init(allowed: [String]) {
            self.allowed = allowed
        }

        func check(_ item: CleaningThreshold) -> [String] {
            if allowed.count == 0 {
                return []
            }
            if !allowed.contains(Kit.Text.normalize(item.timezone)) {
                return ["timezone \(item.timezone) is below minimum"]
            }
            return []
        }
    }

    final class CleaningThresholdEndsAtRangeRule: CleaningThresholdRule {
        var min: Int
        var max: Int

        init(min: Int, max: Int) {
            self.min = min
            self.max = max
        }

        func check(_ item: CleaningThreshold) -> [String] {
            let value = item.endsAt
            if value < min || value > max {
                return ["ends at \(value) is outside \(min) to \(max)"]
            }
            return []
        }
    }

    final class CleaningThresholdLabelLengthRule: CleaningThresholdRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: CleaningThreshold) -> [String] {
            let size = item.label.count
            if size > maxLength {
                return ["label is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class CleaningThresholdRequiredCodeRule: CleaningThresholdRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: CleaningThreshold) -> [String] {
            if item.code.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class CleaningThresholdRequiredTimezoneRule: CleaningThresholdRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: CleaningThreshold) -> [String] {
            if item.timezone.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    /// Runs every rule of a cleaning threshold.
    final class CleaningThresholdValidator {
        var rules: [any CleaningThresholdRule]

        init(rules: [any CleaningThresholdRule]) {
            self.rules = rules
        }

        func validate(_ item: CleaningThreshold) -> [String] {
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

        func requireValid(_ item: CleaningThreshold) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.displayLabel()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [CleaningThreshold]) -> [String: [String]] {
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

    static func defaultCleaningThresholdValidator() -> CleaningThresholdValidator {
        return CleaningThresholdValidator(
            rules: [
                CleaningThresholdTimezoneLengthRule(maxLength: 120),
                CleaningThresholdAllowedTimezoneRule(allowed: ["pending", "batched", "lenient"]),
                CleaningThresholdEndsAtRangeRule(min: 255, max: 3600),
                CleaningThresholdLabelLengthRule(maxLength: 120),
                CleaningThresholdRequiredCodeRule(message: "cleaning threshold needs this field"),
                CleaningThresholdRequiredTimezoneRule(message: "cleaning threshold needs an entry"),
            ]
        )
    }
}
