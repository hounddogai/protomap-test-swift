import AcmePlatform
import Foundation

extension Labs {
    /// A rule a specimen threshold must pass. Check returns its problems, or none.
    protocol SpecimenThresholdRule {
        func check(_ item: SpecimenThreshold) -> [String]
    }

    final class SpecimenThresholdRetriesRangeRule: SpecimenThresholdRule {
        var min: Int
        var max: Int

        init(min: Int, max: Int) {
            self.min = min
            self.max = max
        }

        func check(_ item: SpecimenThreshold) -> [String] {
            let value = item.retries
            var problems: [String] = []
            if value < min {
                problems.append("retries \(value) is below \(min)")
            }
            if value > max {
                problems.append("retries \(value) is above \(max)")
            }
            return problems
        }
    }

    final class SpecimenThresholdCodeLengthRule: SpecimenThresholdRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: SpecimenThreshold) -> [String] {
            let size = item.code.count
            if size > maxLength {
                return ["code is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class SpecimenThresholdRequiredDiagnosisCodeRule: SpecimenThresholdRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: SpecimenThreshold) -> [String] {
            if item.diagnosisCode.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class SpecimenThresholdWindowDaysRangeRule: SpecimenThresholdRule {
        var min: Int
        var max: Int

        init(min: Int, max: Int) {
            self.min = min
            self.max = max
        }

        func check(_ item: SpecimenThreshold) -> [String] {
            let value = item.windowDays
            var problems: [String] = []
            if value < min {
                problems.append("window days \(value) is below \(min)")
            }
            if value > max {
                problems.append("window days \(value) is above \(max)")
            }
            return problems
        }
    }

    final class SpecimenThresholdScoreRangeRule: SpecimenThresholdRule {
        var min: Double
        var max: Double

        init(min: Double, max: Double) {
            self.min = min
            self.max = max
        }

        func check(_ item: SpecimenThreshold) -> [String] {
            let value = item.score
            if value < min || value > max {
                return ["score \(value) is outside \(min) to \(max)"]
            }
            return []
        }
    }

    final class SpecimenThresholdCodePrefixRule: SpecimenThresholdRule {
        var prefix: String

        init(prefix: String) {
            self.prefix = prefix
        }

        func check(_ item: SpecimenThreshold) -> [String] {
            if !item.code.uppercased().hasPrefix(prefix.uppercased()) {
                return ["code must start with \(prefix)"]
            }
            return []
        }
    }

    /// Runs every rule of a specimen threshold.
    final class SpecimenThresholdValidator {
        var rules: [any SpecimenThresholdRule]

        init(rules: [any SpecimenThresholdRule]) {
            self.rules = rules
        }

        func validate(_ item: SpecimenThreshold) -> [String] {
            var problems: [String] = []
            for rule in rules {
                for problem in rule.check(item) {
                    problems.append(problem)
                }
            }
            return problems
        }

        func requireValid(_ item: SpecimenThreshold) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.label()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [SpecimenThreshold]) -> [String: [String]] {
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

    static func defaultSpecimenThresholdValidator() -> SpecimenThresholdValidator {
        return SpecimenThresholdValidator(
            rules: [
                SpecimenThresholdRetriesRangeRule(min: 80, max: 3600),
                SpecimenThresholdCodeLengthRule(maxLength: 16),
                SpecimenThresholdRequiredDiagnosisCodeRule(message: "specimen threshold needs this field"),
                SpecimenThresholdWindowDaysRangeRule(min: 1000, max: 86400),
                SpecimenThresholdScoreRangeRule(min: 6.8, max: 4539.9),
                SpecimenThresholdCodePrefixRule(prefix: "Q"),
            ]
        )
    }
}
