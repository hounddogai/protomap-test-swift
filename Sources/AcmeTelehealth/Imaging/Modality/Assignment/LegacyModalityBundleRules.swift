import AcmePlatform
import Foundation

extension Imaging {
    /// A rule a legacy modality bundle must pass. Check returns its problems, or none.
    protocol LegacyModalityBundleRule {
        func check(_ item: LegacyModalityBundle) -> [String]
    }

    final class LegacyModalityBundleCodePrefixRule: LegacyModalityBundleRule {
        var prefix: String

        init(prefix: String) {
            self.prefix = prefix
        }

        func check(_ item: LegacyModalityBundle) -> [String] {
            if !item.code.uppercased().hasPrefix(prefix.uppercased()) {
                return ["code must start with \(prefix)"]
            }
            return []
        }
    }

    final class LegacyModalityBundleRequiredContactEmailRule: LegacyModalityBundleRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: LegacyModalityBundle) -> [String] {
            if item.contactEmail.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class LegacyModalityBundleAllowedSummaryRule: LegacyModalityBundleRule {
        var allowed: [String]

        init(allowed: [String]) {
            self.allowed = allowed
        }

        func check(_ item: LegacyModalityBundle) -> [String] {
            if allowed.count == 0 {
                return []
            }
            if !allowed.contains(Kit.Text.normalize(item.summary)) {
                return ["summary \(item.summary) is inconsistent"]
            }
            return []
        }
    }

    final class LegacyModalityBundleRequiredPatientRefRule: LegacyModalityBundleRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: LegacyModalityBundle) -> [String] {
            if item.patientRef.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class LegacyModalityBundleRequiredNameRule: LegacyModalityBundleRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: LegacyModalityBundle) -> [String] {
            if item.name.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    /// Runs every rule of a legacy modality bundle.
    final class LegacyModalityBundleValidator {
        var rules: [any LegacyModalityBundleRule]

        init(rules: [any LegacyModalityBundleRule]) {
            self.rules = rules
        }

        func validate(_ item: LegacyModalityBundle) -> [String] {
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

        func requireValid(_ item: LegacyModalityBundle) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.label()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [LegacyModalityBundle]) -> [String: [String]] {
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

    static func defaultLegacyModalityBundleValidator() -> LegacyModalityBundleValidator {
        return LegacyModalityBundleValidator(
            rules: [
                LegacyModalityBundleCodePrefixRule(prefix: "X"),
                LegacyModalityBundleRequiredContactEmailRule(message: "legacy modality bundle needs a value"),
                LegacyModalityBundleAllowedSummaryRule(allowed: ["default", "batched", "default"]),
                LegacyModalityBundleRequiredPatientRefRule(message: "legacy modality bundle needs this field"),
                LegacyModalityBundleRequiredNameRule(message: "legacy modality bundle needs a value"),
            ]
        )
    }
}
