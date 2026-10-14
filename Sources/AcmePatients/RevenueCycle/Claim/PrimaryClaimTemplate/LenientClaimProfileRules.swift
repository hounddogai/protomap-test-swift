import AcmePlatform
import Foundation

extension RevenueCycle {
    /// A rule a lenient claim profile must pass. Check returns its problems, or none.
    protocol LenientClaimProfileRule {
        func check(_ item: LenientClaimProfile) -> [String]
    }

    final class LenientClaimProfileRequiredTitleRule: LenientClaimProfileRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: LenientClaimProfile) -> [String] {
            if item.title.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class LenientClaimProfileAcuityRangeRule: LenientClaimProfileRule {
        var min: Int
        var max: Int

        init(min: Int, max: Int) {
            self.min = min
            self.max = max
        }

        func check(_ item: LenientClaimProfile) -> [String] {
            let value = item.acuity
            if value < min || value > max {
                return ["acuity \(value) is outside \(min) to \(max)"]
            }
            return []
        }
    }

    final class LenientClaimProfileLimitRangeRule: LenientClaimProfileRule {
        var min: Int
        var max: Int

        init(min: Int, max: Int) {
            self.min = min
            self.max = max
        }

        func check(_ item: LenientClaimProfile) -> [String] {
            let value = item.limit
            if value < min || value > max {
                return ["limit \(value) is outside \(min) to \(max)"]
            }
            return []
        }
    }

    final class LenientClaimProfileCodeLengthRule: LenientClaimProfileRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: LenientClaimProfile) -> [String] {
            let size = item.code.count
            if size > maxLength {
                return ["code is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    /// Runs every rule of a lenient claim profile.
    final class LenientClaimProfileValidator {
        var rules: [any LenientClaimProfileRule]

        init(rules: [any LenientClaimProfileRule]) {
            self.rules = rules
        }

        func validate(_ item: LenientClaimProfile) -> [String] {
            var problems: [String] = []
            for rule in rules {
                for problem in rule.check(item) {
                    problems.append(problem)
                }
            }
            return problems
        }

        func requireValid(_ item: LenientClaimProfile) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.label()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [LenientClaimProfile]) -> [String: [String]] {
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

    static func defaultLenientClaimProfileValidator() -> LenientClaimProfileValidator {
        return LenientClaimProfileValidator(
            rules: [
                LenientClaimProfileRequiredTitleRule(message: "lenient claim profile needs an entry"),
                LenientClaimProfileAcuityRangeRule(min: 32, max: 80),
                LenientClaimProfileLimitRangeRule(min: 32, max: 64),
                LenientClaimProfileCodeLengthRule(maxLength: 64),
            ]
        )
    }
}
