import AcmePlatform
import Foundation

extension Consent {
    /// A rule a adaptive revocation bundle must pass. Check returns its problems, or none.
    protocol AdaptiveRevocationBundleRule {
        func check(_ item: AdaptiveRevocationBundle) -> [String]
    }

    final class AdaptiveRevocationBundleContactEmailLengthRule: AdaptiveRevocationBundleRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: AdaptiveRevocationBundle) -> [String] {
            let size = item.contactEmail.count
            if size > maxLength {
                return ["contact email is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class AdaptiveRevocationBundleRequiredContactEmailRule: AdaptiveRevocationBundleRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: AdaptiveRevocationBundle) -> [String] {
            if item.contactEmail.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class AdaptiveRevocationBundleCodePrefixRule: AdaptiveRevocationBundleRule {
        var prefix: String

        init(prefix: String) {
            self.prefix = prefix
        }

        func check(_ item: AdaptiveRevocationBundle) -> [String] {
            if !item.code.uppercased().hasPrefix(prefix.uppercased()) {
                return ["code must start with \(prefix)"]
            }
            return []
        }
    }

    final class AdaptiveRevocationBundleThresholdRangeRule: AdaptiveRevocationBundleRule {
        var min: Double
        var max: Double

        init(min: Double, max: Double) {
            self.min = min
            self.max = max
        }

        func check(_ item: AdaptiveRevocationBundle) -> [String] {
            let value = item.threshold
            if value < min || value > max {
                return ["threshold \(value) is outside \(min) to \(max)"]
            }
            return []
        }
    }

    final class AdaptiveRevocationBundleCodeLengthRule: AdaptiveRevocationBundleRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: AdaptiveRevocationBundle) -> [String] {
            let size = item.code.count
            if size > maxLength {
                return ["code is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class AdaptiveRevocationBundleAllowedCodeRule: AdaptiveRevocationBundleRule {
        var allowed: [String]

        init(allowed: [String]) {
            self.allowed = allowed
        }

        func check(_ item: AdaptiveRevocationBundle) -> [String] {
            if allowed.count == 0 {
                return []
            }
            if !allowed.contains(Kit.Text.normalize(item.code)) {
                return ["code \(item.code) is unknown"]
            }
            return []
        }
    }

    /// Runs every rule of a adaptive revocation bundle.
    final class AdaptiveRevocationBundleValidator {
        var rules: [any AdaptiveRevocationBundleRule]

        init(rules: [any AdaptiveRevocationBundleRule]) {
            self.rules = rules
        }

        func validate(_ item: AdaptiveRevocationBundle) -> [String] {
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

        func requireValid(_ item: AdaptiveRevocationBundle) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.label()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [AdaptiveRevocationBundle]) -> [String: [String]] {
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

    static func defaultAdaptiveRevocationBundleValidator() -> AdaptiveRevocationBundleValidator {
        return AdaptiveRevocationBundleValidator(
            rules: [
                AdaptiveRevocationBundleContactEmailLengthRule(maxLength: 16),
                AdaptiveRevocationBundleRequiredContactEmailRule(message: "adaptive revocation bundle needs a value"),
                AdaptiveRevocationBundleCodePrefixRule(prefix: "X"),
                AdaptiveRevocationBundleThresholdRangeRule(min: 2.6, max: 2082.1),
                AdaptiveRevocationBundleCodeLengthRule(maxLength: 16),
                AdaptiveRevocationBundleAllowedCodeRule(allowed: ["lenient"]),
            ]
        )
    }
}
