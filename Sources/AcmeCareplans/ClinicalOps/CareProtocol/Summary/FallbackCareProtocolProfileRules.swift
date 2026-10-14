import AcmePlatform
import Foundation

extension ClinicalOps {
    /// A rule a fallback care protocol profile must pass. Check returns its problems, or none.
    protocol FallbackCareProtocolProfileRule {
        func check(_ item: FallbackCareProtocolProfile) -> [String]
    }

    final class FallbackCareProtocolProfileRegionLengthRule: FallbackCareProtocolProfileRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: FallbackCareProtocolProfile) -> [String] {
            let size = item.region.count
            if size > maxLength {
                return ["region is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class FallbackCareProtocolProfileRequiredNameRule: FallbackCareProtocolProfileRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: FallbackCareProtocolProfile) -> [String] {
            if item.name.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class FallbackCareProtocolProfileCodeLengthRule: FallbackCareProtocolProfileRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: FallbackCareProtocolProfile) -> [String] {
            let size = item.code.count
            if size > maxLength {
                return ["code is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class FallbackCareProtocolProfileCodePrefixRule: FallbackCareProtocolProfileRule {
        var prefix: String

        init(prefix: String) {
            self.prefix = prefix
        }

        func check(_ item: FallbackCareProtocolProfile) -> [String] {
            if !item.code.uppercased().hasPrefix(prefix.uppercased()) {
                return ["code must start with \(prefix)"]
            }
            return []
        }
    }

    final class FallbackCareProtocolProfileGraceDaysRangeRule: FallbackCareProtocolProfileRule {
        var min: Int
        var max: Int

        init(min: Int, max: Int) {
            self.min = min
            self.max = max
        }

        func check(_ item: FallbackCareProtocolProfile) -> [String] {
            let value = item.graceDays
            if value < min || value > max {
                return ["grace days \(value) is outside \(min) to \(max)"]
            }
            return []
        }
    }

    /// Runs every rule of a fallback care protocol profile.
    final class FallbackCareProtocolProfileValidator {
        var rules: [any FallbackCareProtocolProfileRule]

        init(rules: [any FallbackCareProtocolProfileRule]) {
            self.rules = rules
        }

        func validate(_ item: FallbackCareProtocolProfile) -> [String] {
            var problems: [String] = []
            for rule in rules {
                for problem in rule.check(item) {
                    problems.append(problem)
                }
            }
            return problems
        }

        func requireValid(_ item: FallbackCareProtocolProfile) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.label()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [FallbackCareProtocolProfile]) -> [String: [String]] {
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

    static func defaultFallbackCareProtocolProfileValidator() -> FallbackCareProtocolProfileValidator {
        return FallbackCareProtocolProfileValidator(
            rules: [
                FallbackCareProtocolProfileRegionLengthRule(maxLength: 32),
                FallbackCareProtocolProfileRequiredNameRule(message: "fallback care protocol profile needs an entry"),
                FallbackCareProtocolProfileCodeLengthRule(maxLength: 16),
                FallbackCareProtocolProfileCodePrefixRule(prefix: "X"),
                FallbackCareProtocolProfileGraceDaysRangeRule(min: 255, max: 86400),
            ]
        )
    }
}
