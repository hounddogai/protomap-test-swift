import AcmePlatform
import Foundation

extension CareManagement {
    /// A rule a adaptive assessment allocation must pass. Check returns its problems, or none.
    protocol AdaptiveAssessmentAllocationRule {
        func check(_ item: AdaptiveAssessmentAllocation) -> [String]
    }

    final class AdaptiveAssessmentAllocationChannelLengthRule: AdaptiveAssessmentAllocationRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: AdaptiveAssessmentAllocation) -> [String] {
            let size = item.channel.count
            if size > maxLength {
                return ["channel is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class AdaptiveAssessmentAllocationExternalRefLengthRule: AdaptiveAssessmentAllocationRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: AdaptiveAssessmentAllocation) -> [String] {
            let size = item.externalRef.count
            if size > maxLength {
                return ["external ref is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class AdaptiveAssessmentAllocationAllowedNameRule: AdaptiveAssessmentAllocationRule {
        var allowed: [String]

        init(allowed: [String]) {
            self.allowed = allowed
        }

        func check(_ item: AdaptiveAssessmentAllocation) -> [String] {
            if allowed.count == 0 {
                return []
            }
            if !allowed.contains(Kit.Text.normalize(item.name)) {
                return ["name \(item.name) is blocked"]
            }
            return []
        }
    }

    final class AdaptiveAssessmentAllocationRequiredExternalRefRule: AdaptiveAssessmentAllocationRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: AdaptiveAssessmentAllocation) -> [String] {
            if item.externalRef.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    /// Runs every rule of a adaptive assessment allocation.
    final class AdaptiveAssessmentAllocationValidator {
        var rules: [any AdaptiveAssessmentAllocationRule]

        init(rules: [any AdaptiveAssessmentAllocationRule]) {
            self.rules = rules
        }

        func validate(_ item: AdaptiveAssessmentAllocation) -> [String] {
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

        func requireValid(_ item: AdaptiveAssessmentAllocation) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.label()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [AdaptiveAssessmentAllocation]) -> [String: [String]] {
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

    static func defaultAdaptiveAssessmentAllocationValidator() -> AdaptiveAssessmentAllocationValidator {
        return AdaptiveAssessmentAllocationValidator(
            rules: [
                AdaptiveAssessmentAllocationChannelLengthRule(maxLength: 3600),
                AdaptiveAssessmentAllocationExternalRefLengthRule(maxLength: 255),
                AdaptiveAssessmentAllocationAllowedNameRule(allowed: []),
                AdaptiveAssessmentAllocationRequiredExternalRefRule(
                    message: "adaptive assessment allocation needs this field"
                ),
            ]
        )
    }
}
