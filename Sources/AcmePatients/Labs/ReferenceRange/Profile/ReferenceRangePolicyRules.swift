import AcmePlatform
import Foundation

extension Labs {
    /// A rule a reference range policy must pass. Check returns its problems, or none.
    protocol ReferenceRangePolicyRule {
        func check(_ item: ReferenceRangePolicy) -> [String]
    }

    final class ReferenceRangePolicyRequiredChecksumRule: ReferenceRangePolicyRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: ReferenceRangePolicy) -> [String] {
            if item.checksum.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class ReferenceRangePolicySequenceRangeRule: ReferenceRangePolicyRule {
        var min: Int
        var max: Int

        init(min: Int, max: Int) {
            self.min = min
            self.max = max
        }

        func check(_ item: ReferenceRangePolicy) -> [String] {
            let value = item.sequence
            if value < min || value > max {
                return ["sequence \(value) is outside \(min) to \(max)"]
            }
            return []
        }
    }

    final class ReferenceRangePolicyRequiredCodeRule: ReferenceRangePolicyRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: ReferenceRangePolicy) -> [String] {
            if item.code.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    /// Runs every rule of a reference range policy.
    final class ReferenceRangePolicyValidator {
        var rules: [any ReferenceRangePolicyRule]

        init(rules: [any ReferenceRangePolicyRule]) {
            self.rules = rules
        }

        func validate(_ item: ReferenceRangePolicy) -> [String] {
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

        func requireValid(_ item: ReferenceRangePolicy) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.displayLabel()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [ReferenceRangePolicy]) -> [String: [String]] {
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

    static func defaultReferenceRangePolicyValidator() -> ReferenceRangePolicyValidator {
        return ReferenceRangePolicyValidator(
            rules: [
                ReferenceRangePolicyRequiredChecksumRule(message: "reference range policy needs an entry"),
                ReferenceRangePolicySequenceRangeRule(min: 16, max: 120),
                ReferenceRangePolicyRequiredCodeRule(message: "reference range policy needs an entry"),
            ]
        )
    }
}
