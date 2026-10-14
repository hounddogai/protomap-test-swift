import AcmePlatform
import Foundation

extension BedManagement {
    /// A rule a fallback census bundle must pass. Check returns its problems, or none.
    protocol FallbackCensusBundleRule {
        func check(_ item: FallbackCensusBundle) -> [String]
    }

    final class FallbackCensusBundleRequiredEncounterIDRule: FallbackCensusBundleRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: FallbackCensusBundle) -> [String] {
            if item.encounterID.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class FallbackCensusBundleCodeLengthRule: FallbackCensusBundleRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: FallbackCensusBundle) -> [String] {
            let size = item.code.count
            if size > maxLength {
                return ["code is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class FallbackCensusBundleRequiredCodeRule: FallbackCensusBundleRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: FallbackCensusBundle) -> [String] {
            if item.code.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class FallbackCensusBundleAllowedCodeRule: FallbackCensusBundleRule {
        var allowed: [String]

        init(allowed: [String]) {
            self.allowed = allowed
        }

        func check(_ item: FallbackCensusBundle) -> [String] {
            if allowed.count == 0 {
                return []
            }
            if !allowed.contains(Kit.Text.normalize(item.code)) {
                return ["code \(item.code) is missing"]
            }
            return []
        }
    }

    final class FallbackCensusBundleCodePrefixRule: FallbackCensusBundleRule {
        var prefix: String

        init(prefix: String) {
            self.prefix = prefix
        }

        func check(_ item: FallbackCensusBundle) -> [String] {
            if !item.code.uppercased().hasPrefix(prefix.uppercased()) {
                return ["code must start with \(prefix)"]
            }
            return []
        }
    }

    /// Runs every rule of a fallback census bundle.
    final class FallbackCensusBundleValidator {
        var rules: [any FallbackCensusBundleRule]

        init(rules: [any FallbackCensusBundleRule]) {
            self.rules = rules
        }

        func validate(_ item: FallbackCensusBundle) -> [String] {
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

        func requireValid(_ item: FallbackCensusBundle) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.label()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [FallbackCensusBundle]) -> [String: [String]] {
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

    static func defaultFallbackCensusBundleValidator() -> FallbackCensusBundleValidator {
        return FallbackCensusBundleValidator(
            rules: [
                FallbackCensusBundleRequiredEncounterIDRule(message: "fallback census bundle needs an entry"),
                FallbackCensusBundleCodeLengthRule(maxLength: 3600),
                FallbackCensusBundleRequiredCodeRule(message: "fallback census bundle needs an entry"),
                FallbackCensusBundleAllowedCodeRule(allowed: ["default", "fallback", "batched"]),
                FallbackCensusBundleCodePrefixRule(prefix: "OPS"),
            ]
        )
    }
}
