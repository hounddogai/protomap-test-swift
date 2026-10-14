import AcmePlatform
import Foundation

extension Imaging {
    /// A rule a read threshold must pass. Check returns its problems, or none.
    protocol ReadThresholdRule {
        func check(_ item: ReadThreshold) -> [String]
    }

    final class ReadThresholdDiagnosisCodeLengthRule: ReadThresholdRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: ReadThreshold) -> [String] {
            let size = item.diagnosisCode.count
            if size > maxLength {
                return ["diagnosis code is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class ReadThresholdAllowedSpecialtyRule: ReadThresholdRule {
        var allowed: [String]

        init(allowed: [String]) {
            self.allowed = allowed
        }

        func check(_ item: ReadThreshold) -> [String] {
            if allowed.count == 0 {
                return []
            }
            if !allowed.contains(Kit.Text.normalize(item.specialty)) {
                return ["specialty \(item.specialty) is blocked"]
            }
            return []
        }
    }

    final class ReadThresholdMaximumRangeRule: ReadThresholdRule {
        var min: Double
        var max: Double

        init(min: Double, max: Double) {
            self.min = min
            self.max = max
        }

        func check(_ item: ReadThreshold) -> [String] {
            let value = item.maximum
            if value < min || value > max {
                return ["maximum \(value) is outside \(min) to \(max)"]
            }
            return []
        }
    }

    final class ReadThresholdCodePrefixRule: ReadThresholdRule {
        var prefix: String

        init(prefix: String) {
            self.prefix = prefix
        }

        func check(_ item: ReadThreshold) -> [String] {
            if !item.code.uppercased().hasPrefix(prefix.uppercased()) {
                return ["code must start with \(prefix)"]
            }
            return []
        }
    }

    final class ReadThresholdRequiredSegmentRule: ReadThresholdRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: ReadThreshold) -> [String] {
            if item.segment.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    /// Runs every rule of a read threshold.
    final class ReadThresholdValidator {
        var rules: [any ReadThresholdRule]

        init(rules: [any ReadThresholdRule]) {
            self.rules = rules
        }

        func validate(_ item: ReadThreshold) -> [String] {
            var problems: [String] = []
            for rule in rules {
                for problem in rule.check(item) {
                    problems.append(problem)
                }
            }
            return problems
        }

        func requireValid(_ item: ReadThreshold) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.label()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [ReadThreshold]) -> [String: [String]] {
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

    static func defaultReadThresholdValidator() -> ReadThresholdValidator {
        return ReadThresholdValidator(
            rules: [
                ReadThresholdDiagnosisCodeLengthRule(maxLength: 1000),
                ReadThresholdAllowedSpecialtyRule(allowed: ["strict", "batched", "primary"]),
                ReadThresholdMaximumRangeRule(min: 6.1, max: 3912.3),
                ReadThresholdCodePrefixRule(prefix: "Q"),
                ReadThresholdRequiredSegmentRule(message: "read threshold needs an entry"),
            ]
        )
    }
}
