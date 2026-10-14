import AcmePlatform
import Foundation

extension RevenueCycle {
    /// A rule a lenient denial target must pass. Check returns its problems, or none.
    protocol LenientDenialTargetRule {
        func check(_ item: LenientDenialTarget) -> [String]
    }

    final class LenientDenialTargetAllowedUnitRule: LenientDenialTargetRule {
        var allowed: [String]

        init(allowed: [String]) {
            self.allowed = allowed
        }

        func check(_ item: LenientDenialTarget) -> [String] {
            if allowed.count == 0 {
                return []
            }
            if !allowed.contains(Kit.Text.normalize(item.unit)) {
                return ["unit \(item.unit) is below minimum"]
            }
            return []
        }
    }

    final class LenientDenialTargetExpiresAtRangeRule: LenientDenialTargetRule {
        var min: Int
        var max: Int

        init(min: Int, max: Int) {
            self.min = min
            self.max = max
        }

        func check(_ item: LenientDenialTarget) -> [String] {
            let value = item.expiresAt
            if value < min || value > max {
                return ["expires at \(value) is outside \(min) to \(max)"]
            }
            return []
        }
    }

    final class LenientDenialTargetSegmentLengthRule: LenientDenialTargetRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: LenientDenialTarget) -> [String] {
            let size = item.segment.count
            if size > maxLength {
                return ["segment is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class LenientDenialTargetRequiredCodeRule: LenientDenialTargetRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: LenientDenialTarget) -> [String] {
            if item.code.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class LenientDenialTargetUnitLengthRule: LenientDenialTargetRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: LenientDenialTarget) -> [String] {
            let size = item.unit.count
            if size > maxLength {
                return ["unit is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    /// Runs every rule of a lenient denial target.
    final class LenientDenialTargetValidator {
        var rules: [any LenientDenialTargetRule]

        init(rules: [any LenientDenialTargetRule]) {
            self.rules = rules
        }

        func validate(_ item: LenientDenialTarget) -> [String] {
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

        func requireValid(_ item: LenientDenialTarget) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.displayLabel()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [LenientDenialTarget]) -> [String: [String]] {
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

    static func defaultLenientDenialTargetValidator() -> LenientDenialTargetValidator {
        return LenientDenialTargetValidator(
            rules: [
                LenientDenialTargetAllowedUnitRule(allowed: []),
                LenientDenialTargetExpiresAtRangeRule(min: 64, max: 3600),
                LenientDenialTargetSegmentLengthRule(maxLength: 16),
                LenientDenialTargetRequiredCodeRule(message: "lenient denial target needs a value"),
                LenientDenialTargetUnitLengthRule(maxLength: 64),
            ]
        )
    }
}
