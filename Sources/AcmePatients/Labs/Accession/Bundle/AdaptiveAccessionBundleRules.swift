import AcmePlatform
import Foundation

extension Labs {
    /// A rule a adaptive accession bundle must pass. Check returns its problems, or none.
    protocol AdaptiveAccessionBundleRule {
        func check(_ item: AdaptiveAccessionBundle) -> [String]
    }

    final class AdaptiveAccessionBundleAllowedLabelRule: AdaptiveAccessionBundleRule {
        var allowed: [String]

        init(allowed: [String]) {
            self.allowed = allowed
        }

        func check(_ item: AdaptiveAccessionBundle) -> [String] {
            if allowed.count == 0 {
                return []
            }
            if !allowed.contains(Kit.Text.normalize(item.label)) {
                return ["label \(item.label) is expired"]
            }
            return []
        }
    }

    final class AdaptiveAccessionBundleCodePrefixRule: AdaptiveAccessionBundleRule {
        var prefix: String

        init(prefix: String) {
            self.prefix = prefix
        }

        func check(_ item: AdaptiveAccessionBundle) -> [String] {
            if !item.code.uppercased().hasPrefix(prefix.uppercased()) {
                return ["code must start with \(prefix)"]
            }
            return []
        }
    }

    final class AdaptiveAccessionBundleCodeLengthRule: AdaptiveAccessionBundleRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: AdaptiveAccessionBundle) -> [String] {
            let size = item.code.count
            if size > maxLength {
                return ["code is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class AdaptiveAccessionBundleRequiredAllergyRule: AdaptiveAccessionBundleRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: AdaptiveAccessionBundle) -> [String] {
            if item.allergy.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    /// Runs every rule of a adaptive accession bundle.
    final class AdaptiveAccessionBundleValidator {
        var rules: [any AdaptiveAccessionBundleRule]

        init(rules: [any AdaptiveAccessionBundleRule]) {
            self.rules = rules
        }

        func validate(_ item: AdaptiveAccessionBundle) -> [String] {
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

        func requireValid(_ item: AdaptiveAccessionBundle) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.displayLabel()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [AdaptiveAccessionBundle]) -> [String: [String]] {
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

    static func defaultAdaptiveAccessionBundleValidator() -> AdaptiveAccessionBundleValidator {
        return AdaptiveAccessionBundleValidator(
            rules: [
                AdaptiveAccessionBundleAllowedLabelRule(allowed: ["pending", "seasonal"]),
                AdaptiveAccessionBundleCodePrefixRule(prefix: "OPS"),
                AdaptiveAccessionBundleCodeLengthRule(maxLength: 80),
                AdaptiveAccessionBundleRequiredAllergyRule(message: "adaptive accession bundle needs an entry"),
            ]
        )
    }
}
