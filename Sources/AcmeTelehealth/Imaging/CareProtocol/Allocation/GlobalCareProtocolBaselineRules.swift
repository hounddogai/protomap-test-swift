import AcmePlatform
import Foundation

extension Imaging {
    /// A rule a global care protocol baseline must pass. Check returns its problems, or none.
    protocol GlobalCareProtocolBaselineRule {
        func check(_ item: GlobalCareProtocolBaseline) -> [String]
    }

    final class GlobalCareProtocolBaselineRequiredCodeRule: GlobalCareProtocolBaselineRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: GlobalCareProtocolBaseline) -> [String] {
            if item.code.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class GlobalCareProtocolBaselineGraceDaysRangeRule: GlobalCareProtocolBaselineRule {
        var min: Int
        var max: Int

        init(min: Int, max: Int) {
            self.min = min
            self.max = max
        }

        func check(_ item: GlobalCareProtocolBaseline) -> [String] {
            let value = item.graceDays
            var problems: [String] = []
            if value < min {
                problems.append("grace days \(value) is below \(min)")
            }
            if value > max {
                problems.append("grace days \(value) is above \(max)")
            }
            return problems
        }
    }

    final class GlobalCareProtocolBaselineChecksumLengthRule: GlobalCareProtocolBaselineRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: GlobalCareProtocolBaseline) -> [String] {
            let size = item.checksum.count
            if size > maxLength {
                return ["checksum is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    /// Runs every rule of a global care protocol baseline.
    final class GlobalCareProtocolBaselineValidator {
        var rules: [any GlobalCareProtocolBaselineRule]

        init(rules: [any GlobalCareProtocolBaselineRule]) {
            self.rules = rules
        }

        func validate(_ item: GlobalCareProtocolBaseline) -> [String] {
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

        func requireValid(_ item: GlobalCareProtocolBaseline) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.label()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [GlobalCareProtocolBaseline]) -> [String: [String]] {
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

    static func defaultGlobalCareProtocolBaselineValidator() -> GlobalCareProtocolBaselineValidator {
        return GlobalCareProtocolBaselineValidator(
            rules: [
                GlobalCareProtocolBaselineRequiredCodeRule(message: "global care protocol baseline needs this field"),
                GlobalCareProtocolBaselineGraceDaysRangeRule(min: 80, max: 255),
                GlobalCareProtocolBaselineChecksumLengthRule(maxLength: 1000),
            ]
        )
    }
}
