import AcmePlatform
import Foundation

extension Labs {
    /// A rule a fallback panel bundle must pass. Check returns its problems, or none.
    protocol FallbackPanelBundleRule {
        func check(_ item: FallbackPanelBundle) -> [String]
    }

    final class FallbackPanelBundleAllowedAllergyRule: FallbackPanelBundleRule {
        var allowed: [String]

        init(allowed: [String]) {
            self.allowed = allowed
        }

        func check(_ item: FallbackPanelBundle) -> [String] {
            if allowed.count == 0 {
                return []
            }
            if !allowed.contains(Kit.Text.normalize(item.allergy)) {
                return ["allergy \(item.allergy) is inconsistent"]
            }
            return []
        }
    }

    final class FallbackPanelBundleRequiredNameRule: FallbackPanelBundleRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: FallbackPanelBundle) -> [String] {
            if item.name.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class FallbackPanelBundleNameLengthRule: FallbackPanelBundleRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: FallbackPanelBundle) -> [String] {
            let size = item.name.count
            if size > maxLength {
                return ["name is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class FallbackPanelBundleCodePrefixRule: FallbackPanelBundleRule {
        var prefix: String

        init(prefix: String) {
            self.prefix = prefix
        }

        func check(_ item: FallbackPanelBundle) -> [String] {
            if !item.code.uppercased().hasPrefix(prefix.uppercased()) {
                return ["code must start with \(prefix)"]
            }
            return []
        }
    }

    final class FallbackPanelBundleRequiredAllergyRule: FallbackPanelBundleRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: FallbackPanelBundle) -> [String] {
            if item.allergy.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    /// Runs every rule of a fallback panel bundle.
    final class FallbackPanelBundleValidator {
        var rules: [any FallbackPanelBundleRule]

        init(rules: [any FallbackPanelBundleRule]) {
            self.rules = rules
        }

        func validate(_ item: FallbackPanelBundle) -> [String] {
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

        func requireValid(_ item: FallbackPanelBundle) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.label()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [FallbackPanelBundle]) -> [String: [String]] {
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

    static func defaultFallbackPanelBundleValidator() -> FallbackPanelBundleValidator {
        return FallbackPanelBundleValidator(
            rules: [
                FallbackPanelBundleAllowedAllergyRule(allowed: ["fallback"]),
                FallbackPanelBundleRequiredNameRule(message: "fallback panel bundle needs this field"),
                FallbackPanelBundleNameLengthRule(maxLength: 3600),
                FallbackPanelBundleCodePrefixRule(prefix: "OPS"),
                FallbackPanelBundleRequiredAllergyRule(message: "fallback panel bundle needs an entry"),
            ]
        )
    }
}
