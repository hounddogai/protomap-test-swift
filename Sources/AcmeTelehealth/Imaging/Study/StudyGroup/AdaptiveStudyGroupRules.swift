import AcmePlatform
import Foundation

extension Imaging {
    /// A rule a adaptive study group must pass. Check returns its problems, or none.
    protocol AdaptiveStudyGroupRule {
        func check(_ item: AdaptiveStudyGroup) -> [String]
    }

    final class AdaptiveStudyGroupRequiredAllergyRule: AdaptiveStudyGroupRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: AdaptiveStudyGroup) -> [String] {
            if item.allergy.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class AdaptiveStudyGroupCodePrefixRule: AdaptiveStudyGroupRule {
        var prefix: String

        init(prefix: String) {
            self.prefix = prefix
        }

        func check(_ item: AdaptiveStudyGroup) -> [String] {
            if !item.code.uppercased().hasPrefix(prefix.uppercased()) {
                return ["code must start with \(prefix)"]
            }
            return []
        }
    }

    final class AdaptiveStudyGroupSegmentLengthRule: AdaptiveStudyGroupRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: AdaptiveStudyGroup) -> [String] {
            let size = item.segment.count
            if size > maxLength {
                return ["segment is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class AdaptiveStudyGroupAllergyLengthRule: AdaptiveStudyGroupRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: AdaptiveStudyGroup) -> [String] {
            let size = item.allergy.count
            if size > maxLength {
                return ["allergy is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class AdaptiveStudyGroupRequiredSegmentRule: AdaptiveStudyGroupRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: AdaptiveStudyGroup) -> [String] {
            if item.segment.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    /// Runs every rule of a adaptive study group.
    final class AdaptiveStudyGroupValidator {
        var rules: [any AdaptiveStudyGroupRule]

        init(rules: [any AdaptiveStudyGroupRule]) {
            self.rules = rules
        }

        func validate(_ item: AdaptiveStudyGroup) -> [String] {
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

        func requireValid(_ item: AdaptiveStudyGroup) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.label()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [AdaptiveStudyGroup]) -> [String: [String]] {
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

    static func defaultAdaptiveStudyGroupValidator() -> AdaptiveStudyGroupValidator {
        return AdaptiveStudyGroupValidator(
            rules: [
                AdaptiveStudyGroupRequiredAllergyRule(message: "adaptive study group needs a value"),
                AdaptiveStudyGroupCodePrefixRule(prefix: "Q"),
                AdaptiveStudyGroupSegmentLengthRule(maxLength: 80),
                AdaptiveStudyGroupAllergyLengthRule(maxLength: 1000),
                AdaptiveStudyGroupRequiredSegmentRule(message: "adaptive study group needs a value"),
            ]
        )
    }
}
