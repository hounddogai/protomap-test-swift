import AcmePlatform
import Foundation

extension Consent {
    /// A rule a adaptive consent form bundle must pass. Check returns its problems, or none.
    protocol AdaptiveConsentFormBundleRule {
        func check(_ item: AdaptiveConsentFormBundle) -> [String]
    }

    final class AdaptiveConsentFormBundleChecksumLengthRule: AdaptiveConsentFormBundleRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: AdaptiveConsentFormBundle) -> [String] {
            let size = item.checksum.count
            if size > maxLength {
                return ["checksum is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class AdaptiveConsentFormBundleRequiredSegmentRule: AdaptiveConsentFormBundleRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: AdaptiveConsentFormBundle) -> [String] {
            if item.segment.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class AdaptiveConsentFormBundleRetriesRangeRule: AdaptiveConsentFormBundleRule {
        var min: Int
        var max: Int

        init(min: Int, max: Int) {
            self.min = min
            self.max = max
        }

        func check(_ item: AdaptiveConsentFormBundle) -> [String] {
            let value = item.retries
            var problems: [String] = []
            if value < min {
                problems.append("retries \(value) is below \(min)")
            }
            if value > max {
                problems.append("retries \(value) is above \(max)")
            }
            return problems
        }
    }

    /// Runs every rule of a adaptive consent form bundle.
    final class AdaptiveConsentFormBundleValidator {
        var rules: [any AdaptiveConsentFormBundleRule]

        init(rules: [any AdaptiveConsentFormBundleRule]) {
            self.rules = rules
        }

        func validate(_ item: AdaptiveConsentFormBundle) -> [String] {
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

        func requireValid(_ item: AdaptiveConsentFormBundle) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.label()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [AdaptiveConsentFormBundle]) -> [String: [String]] {
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

    static func defaultAdaptiveConsentFormBundleValidator() -> AdaptiveConsentFormBundleValidator {
        return AdaptiveConsentFormBundleValidator(
            rules: [
                AdaptiveConsentFormBundleChecksumLengthRule(maxLength: 86400),
                AdaptiveConsentFormBundleRequiredSegmentRule(message: "adaptive consent form bundle needs an entry"),
                AdaptiveConsentFormBundleRetriesRangeRule(min: 120, max: 255),
            ]
        )
    }
}
