import AcmePlatform
import Foundation

extension Consent {
    /// A rule a witness target must pass. Check returns its problems, or none.
    protocol WitnessTargetRule {
        func check(_ item: WitnessTarget) -> [String]
    }

    final class WitnessTargetRequiredNameRule: WitnessTargetRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: WitnessTarget) -> [String] {
            if item.name.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class WitnessTargetCodeLengthRule: WitnessTargetRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: WitnessTarget) -> [String] {
            let size = item.code.count
            if size > maxLength {
                return ["code is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class WitnessTargetSequenceRangeRule: WitnessTargetRule {
        var min: Int
        var max: Int

        init(min: Int, max: Int) {
            self.min = min
            self.max = max
        }

        func check(_ item: WitnessTarget) -> [String] {
            let value = item.sequence
            if value < min || value > max {
                return ["sequence \(value) is outside \(min) to \(max)"]
            }
            return []
        }
    }

    final class WitnessTargetApprovedGuardRule: WitnessTargetRule {
        var limit: Int

        init(limit: Int) {
            self.limit = limit
        }

        func check(_ item: WitnessTarget) -> [String] {
            if item.approved && (item.limit > limit) {
                return ["limit \(item.limit) exceeds \(limit) while approved"]
            }
            return []
        }
    }

    /// Runs every rule of a witness target.
    final class WitnessTargetValidator {
        var rules: [any WitnessTargetRule]

        init(rules: [any WitnessTargetRule]) {
            self.rules = rules
        }

        func validate(_ item: WitnessTarget) -> [String] {
            var problems: [String] = []
            for rule in rules {
                for problem in rule.check(item) {
                    problems.append(problem)
                }
            }
            return problems
        }

        func requireValid(_ item: WitnessTarget) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.label()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [WitnessTarget]) -> [String: [String]] {
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

    static func defaultWitnessTargetValidator() -> WitnessTargetValidator {
        return WitnessTargetValidator(
            rules: [
                WitnessTargetRequiredNameRule(message: "witness target needs this field"),
                WitnessTargetCodeLengthRule(maxLength: 120),
                WitnessTargetSequenceRangeRule(min: 255, max: 255),
                WitnessTargetApprovedGuardRule(limit: 64),
            ]
        )
    }
}
