import AcmePlatform
import Foundation

extension Consent {
    /// A rule a adaptive witness digest must pass. Check returns its problems, or none.
    protocol AdaptiveWitnessDigestRule {
        func check(_ item: AdaptiveWitnessDigest) -> [String]
    }

    final class AdaptiveWitnessDigestCodeLengthRule: AdaptiveWitnessDigestRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: AdaptiveWitnessDigest) -> [String] {
            let size = item.code.count
            if size > maxLength {
                return ["code is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class AdaptiveWitnessDigestRequiredExternalRefRule: AdaptiveWitnessDigestRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: AdaptiveWitnessDigest) -> [String] {
            if item.externalRef.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class AdaptiveWitnessDigestStartsAtRangeRule: AdaptiveWitnessDigestRule {
        var min: Int
        var max: Int

        init(min: Int, max: Int) {
            self.min = min
            self.max = max
        }

        func check(_ item: AdaptiveWitnessDigest) -> [String] {
            let value = item.startsAt
            if value < min || value > max {
                return ["starts at \(value) is outside \(min) to \(max)"]
            }
            return []
        }
    }

    /// Runs every rule of a adaptive witness digest.
    final class AdaptiveWitnessDigestValidator {
        var rules: [any AdaptiveWitnessDigestRule]

        init(rules: [any AdaptiveWitnessDigestRule]) {
            self.rules = rules
        }

        func validate(_ item: AdaptiveWitnessDigest) -> [String] {
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

        func requireValid(_ item: AdaptiveWitnessDigest) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.label()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [AdaptiveWitnessDigest]) -> [String: [String]] {
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

    static func defaultAdaptiveWitnessDigestValidator() -> AdaptiveWitnessDigestValidator {
        return AdaptiveWitnessDigestValidator(
            rules: [
                AdaptiveWitnessDigestCodeLengthRule(maxLength: 120),
                AdaptiveWitnessDigestRequiredExternalRefRule(message: "adaptive witness digest needs an entry"),
                AdaptiveWitnessDigestStartsAtRangeRule(min: 1000, max: 86400),
            ]
        )
    }
}
