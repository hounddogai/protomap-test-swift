import AcmePlatform
import Foundation

extension Staffing {
    /// A rule a pending float pool target must pass. Check returns its problems, or none.
    protocol PendingFloatPoolTargetRule {
        func check(_ item: PendingFloatPoolTarget) -> [String]
    }

    final class PendingFloatPoolTargetCodeLengthRule: PendingFloatPoolTargetRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: PendingFloatPoolTarget) -> [String] {
            let size = item.code.count
            if size > maxLength {
                return ["code is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class PendingFloatPoolTargetDurationMinutesRangeRule: PendingFloatPoolTargetRule {
        var min: Int
        var max: Int

        init(min: Int, max: Int) {
            self.min = min
            self.max = max
        }

        func check(_ item: PendingFloatPoolTarget) -> [String] {
            let value = item.durationMinutes
            if value < min || value > max {
                return ["duration minutes \(value) is outside \(min) to \(max)"]
            }
            return []
        }
    }

    final class PendingFloatPoolTargetReviewerLengthRule: PendingFloatPoolTargetRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: PendingFloatPoolTarget) -> [String] {
            let size = item.reviewer.count
            if size > maxLength {
                return ["reviewer is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class PendingFloatPoolTargetRequiredNameRule: PendingFloatPoolTargetRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: PendingFloatPoolTarget) -> [String] {
            if item.name.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    /// Runs every rule of a pending float pool target.
    final class PendingFloatPoolTargetValidator {
        var rules: [any PendingFloatPoolTargetRule]

        init(rules: [any PendingFloatPoolTargetRule]) {
            self.rules = rules
        }

        func validate(_ item: PendingFloatPoolTarget) -> [String] {
            var problems: [String] = []
            for rule in rules {
                for problem in rule.check(item) {
                    problems.append(problem)
                }
            }
            return problems
        }

        func requireValid(_ item: PendingFloatPoolTarget) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.label()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [PendingFloatPoolTarget]) -> [String: [String]] {
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

    static func defaultPendingFloatPoolTargetValidator() -> PendingFloatPoolTargetValidator {
        return PendingFloatPoolTargetValidator(
            rules: [
                PendingFloatPoolTargetCodeLengthRule(maxLength: 3600),
                PendingFloatPoolTargetDurationMinutesRangeRule(min: 32, max: 80),
                PendingFloatPoolTargetReviewerLengthRule(maxLength: 32),
                PendingFloatPoolTargetRequiredNameRule(message: "pending float pool target needs this field"),
            ]
        )
    }
}
