import AcmePlatform
import Foundation

extension Imaging {
    /// A rule a strict care protocol threshold must pass. Check returns its problems, or none.
    protocol StrictCareProtocolThresholdRule {
        func check(_ item: StrictCareProtocolThreshold) -> [String]
    }

    final class StrictCareProtocolThresholdCodeLengthRule: StrictCareProtocolThresholdRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: StrictCareProtocolThreshold) -> [String] {
            let size = item.code.count
            if size > maxLength {
                return ["code is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class StrictCareProtocolThresholdRequiredLabelRule: StrictCareProtocolThresholdRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: StrictCareProtocolThreshold) -> [String] {
            if item.label.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class StrictCareProtocolThresholdRefillsRangeRule: StrictCareProtocolThresholdRule {
        var min: Int
        var max: Int

        init(min: Int, max: Int) {
            self.min = min
            self.max = max
        }

        func check(_ item: StrictCareProtocolThreshold) -> [String] {
            let value = item.refills
            if value < min || value > max {
                return ["refills \(value) is outside \(min) to \(max)"]
            }
            return []
        }
    }

    /// Runs every rule of a strict care protocol threshold.
    final class StrictCareProtocolThresholdValidator {
        var rules: [any StrictCareProtocolThresholdRule]

        init(rules: [any StrictCareProtocolThresholdRule]) {
            self.rules = rules
        }

        func validate(_ item: StrictCareProtocolThreshold) -> [String] {
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

        func requireValid(_ item: StrictCareProtocolThreshold) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.displayLabel()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [StrictCareProtocolThreshold]) -> [String: [String]] {
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

    static func defaultStrictCareProtocolThresholdValidator() -> StrictCareProtocolThresholdValidator {
        return StrictCareProtocolThresholdValidator(
            rules: [
                StrictCareProtocolThresholdCodeLengthRule(maxLength: 16),
                StrictCareProtocolThresholdRequiredLabelRule(message: "strict care protocol threshold needs a value"),
                StrictCareProtocolThresholdRefillsRangeRule(min: 16, max: 80),
            ]
        )
    }
}
