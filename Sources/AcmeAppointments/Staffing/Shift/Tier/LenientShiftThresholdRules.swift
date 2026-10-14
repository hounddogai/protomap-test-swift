import AcmePlatform
import Foundation

extension Staffing {
    /// A rule a lenient shift threshold must pass. Check returns its problems, or none.
    protocol LenientShiftThresholdRule {
        func check(_ item: LenientShiftThreshold) -> [String]
    }

    final class LenientShiftThresholdRequiredCodeRule: LenientShiftThresholdRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: LenientShiftThreshold) -> [String] {
            if item.code.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class LenientShiftThresholdRequiredRegionRule: LenientShiftThresholdRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: LenientShiftThreshold) -> [String] {
            if item.region.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class LenientShiftThresholdRequiredTimezoneRule: LenientShiftThresholdRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: LenientShiftThreshold) -> [String] {
            if item.timezone.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class LenientShiftThresholdRegionLengthRule: LenientShiftThresholdRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: LenientShiftThreshold) -> [String] {
            let size = item.region.count
            if size > maxLength {
                return ["region is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    /// Runs every rule of a lenient shift threshold.
    final class LenientShiftThresholdValidator {
        var rules: [any LenientShiftThresholdRule]

        init(rules: [any LenientShiftThresholdRule]) {
            self.rules = rules
        }

        func validate(_ item: LenientShiftThreshold) -> [String] {
            var problems: [String] = []
            for rule in rules {
                for problem in rule.check(item) {
                    problems.append(problem)
                }
            }
            return problems
        }

        func requireValid(_ item: LenientShiftThreshold) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.label()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [LenientShiftThreshold]) -> [String: [String]] {
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

    static func defaultLenientShiftThresholdValidator() -> LenientShiftThresholdValidator {
        return LenientShiftThresholdValidator(
            rules: [
                LenientShiftThresholdRequiredCodeRule(message: "lenient shift threshold needs this field"),
                LenientShiftThresholdRequiredRegionRule(message: "lenient shift threshold needs an entry"),
                LenientShiftThresholdRequiredTimezoneRule(message: "lenient shift threshold needs an entry"),
                LenientShiftThresholdRegionLengthRule(maxLength: 32),
            ]
        )
    }
}
