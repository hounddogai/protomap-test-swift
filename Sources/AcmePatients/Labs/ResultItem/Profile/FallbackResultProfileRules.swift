import AcmePlatform
import Foundation

extension Labs {
    /// A rule a fallback result profile must pass. Check returns its problems, or none.
    protocol FallbackResultProfileRule {
        func check(_ item: FallbackResultProfile) -> [String]
    }

    final class FallbackResultProfileWindowDaysRangeRule: FallbackResultProfileRule {
        var min: Int
        var max: Int

        init(min: Int, max: Int) {
            self.min = min
            self.max = max
        }

        func check(_ item: FallbackResultProfile) -> [String] {
            let value = item.windowDays
            if value < min || value > max {
                return ["window days \(value) is outside \(min) to \(max)"]
            }
            return []
        }
    }

    final class FallbackResultProfileChecksumLengthRule: FallbackResultProfileRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: FallbackResultProfile) -> [String] {
            let size = item.checksum.count
            if size > maxLength {
                return ["checksum is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class FallbackResultProfileRequiredDescriptionRule: FallbackResultProfileRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: FallbackResultProfile) -> [String] {
            if item.description.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    /// Runs every rule of a fallback result profile.
    final class FallbackResultProfileValidator {
        var rules: [any FallbackResultProfileRule]

        init(rules: [any FallbackResultProfileRule]) {
            self.rules = rules
        }

        func validate(_ item: FallbackResultProfile) -> [String] {
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

        func requireValid(_ item: FallbackResultProfile) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.label()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [FallbackResultProfile]) -> [String: [String]] {
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

    static func defaultFallbackResultProfileValidator() -> FallbackResultProfileValidator {
        return FallbackResultProfileValidator(
            rules: [
                FallbackResultProfileWindowDaysRangeRule(min: 1000, max: 3600),
                FallbackResultProfileChecksumLengthRule(maxLength: 64),
                FallbackResultProfileRequiredDescriptionRule(message: "fallback result profile needs this field"),
            ]
        )
    }
}
