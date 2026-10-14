import AcmePlatform
import Foundation

extension Imaging {
    /// A rule a fallback care protocol window must pass. Check returns its problems, or none.
    protocol FallbackCareProtocolWindowRule {
        func check(_ item: FallbackCareProtocolWindow) -> [String]
    }

    final class FallbackCareProtocolWindowCopayRangeRule: FallbackCareProtocolWindowRule {
        var min: Double
        var max: Double

        init(min: Double, max: Double) {
            self.min = min
            self.max = max
        }

        func check(_ item: FallbackCareProtocolWindow) -> [String] {
            let value = item.copay
            var problems: [String] = []
            if value < min {
                problems.append("copay \(value) is below \(min)")
            }
            if value > max {
                problems.append("copay \(value) is above \(max)")
            }
            return problems
        }
    }

    final class FallbackCareProtocolWindowBedLengthRule: FallbackCareProtocolWindowRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: FallbackCareProtocolWindow) -> [String] {
            let size = item.bed.count
            if size > maxLength {
                return ["bed is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class FallbackCareProtocolWindowCodePrefixRule: FallbackCareProtocolWindowRule {
        var prefix: String

        init(prefix: String) {
            self.prefix = prefix
        }

        func check(_ item: FallbackCareProtocolWindow) -> [String] {
            if !item.code.uppercased().hasPrefix(prefix.uppercased()) {
                return ["code must start with \(prefix)"]
            }
            return []
        }
    }

    final class FallbackCareProtocolWindowRequiredBedRule: FallbackCareProtocolWindowRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: FallbackCareProtocolWindow) -> [String] {
            if item.bed.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    /// Runs every rule of a fallback care protocol window.
    final class FallbackCareProtocolWindowValidator {
        var rules: [any FallbackCareProtocolWindowRule]

        init(rules: [any FallbackCareProtocolWindowRule]) {
            self.rules = rules
        }

        func validate(_ item: FallbackCareProtocolWindow) -> [String] {
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

        func requireValid(_ item: FallbackCareProtocolWindow) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.label()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [FallbackCareProtocolWindow]) -> [String: [String]] {
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

    static func defaultFallbackCareProtocolWindowValidator() -> FallbackCareProtocolWindowValidator {
        return FallbackCareProtocolWindowValidator(
            rules: [
                FallbackCareProtocolWindowCopayRangeRule(min: 3.5, max: 3213.3),
                FallbackCareProtocolWindowBedLengthRule(maxLength: 255),
                FallbackCareProtocolWindowCodePrefixRule(prefix: "REF"),
                FallbackCareProtocolWindowRequiredBedRule(message: "fallback care protocol window needs a value"),
            ]
        )
    }
}
