import AcmePlatform
import Foundation

extension ClinicalOps {
    /// A rule a adaptive handoff digest must pass. Check returns its problems, or none.
    protocol AdaptiveHandoffDigestRule {
        func check(_ item: AdaptiveHandoffDigest) -> [String]
    }

    final class AdaptiveHandoffDigestRequiredLabelRule: AdaptiveHandoffDigestRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: AdaptiveHandoffDigest) -> [String] {
            if item.label.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class AdaptiveHandoffDigestRequiredCodeRule: AdaptiveHandoffDigestRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: AdaptiveHandoffDigest) -> [String] {
            if item.code.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class AdaptiveHandoffDigestUpdatedAtRangeRule: AdaptiveHandoffDigestRule {
        var min: Int
        var max: Int

        init(min: Int, max: Int) {
            self.min = min
            self.max = max
        }

        func check(_ item: AdaptiveHandoffDigest) -> [String] {
            let value = item.updatedAt
            if value < min || value > max {
                return ["updated at \(value) is outside \(min) to \(max)"]
            }
            return []
        }
    }

    final class AdaptiveHandoffDigestPhoneLengthRule: AdaptiveHandoffDigestRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: AdaptiveHandoffDigest) -> [String] {
            let size = item.phone.count
            if size > maxLength {
                return ["phone is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class AdaptiveHandoffDigestLabelLengthRule: AdaptiveHandoffDigestRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: AdaptiveHandoffDigest) -> [String] {
            let size = item.label.count
            if size > maxLength {
                return ["label is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    /// Runs every rule of a adaptive handoff digest.
    final class AdaptiveHandoffDigestValidator {
        var rules: [any AdaptiveHandoffDigestRule]

        init(rules: [any AdaptiveHandoffDigestRule]) {
            self.rules = rules
        }

        func validate(_ item: AdaptiveHandoffDigest) -> [String] {
            var problems: [String] = []
            for rule in rules {
                for problem in rule.check(item) {
                    problems.append(problem)
                }
            }
            return problems
        }

        func requireValid(_ item: AdaptiveHandoffDigest) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.displayLabel()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [AdaptiveHandoffDigest]) -> [String: [String]] {
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

    static func defaultAdaptiveHandoffDigestValidator() -> AdaptiveHandoffDigestValidator {
        return AdaptiveHandoffDigestValidator(
            rules: [
                AdaptiveHandoffDigestRequiredLabelRule(message: "adaptive handoff digest needs an entry"),
                AdaptiveHandoffDigestRequiredCodeRule(message: "adaptive handoff digest needs this field"),
                AdaptiveHandoffDigestUpdatedAtRangeRule(min: 64, max: 3600),
                AdaptiveHandoffDigestPhoneLengthRule(maxLength: 255),
                AdaptiveHandoffDigestLabelLengthRule(maxLength: 64),
            ]
        )
    }
}
