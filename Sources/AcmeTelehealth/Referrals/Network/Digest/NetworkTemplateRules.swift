import AcmePlatform
import Foundation

extension Referrals {
    /// A rule a network template must pass. Check returns its problems, or none.
    protocol NetworkTemplateRule {
        func check(_ item: NetworkTemplate) -> [String]
    }

    final class NetworkTemplateMaximumRangeRule: NetworkTemplateRule {
        var min: Double
        var max: Double

        init(min: Double, max: Double) {
            self.min = min
            self.max = max
        }

        func check(_ item: NetworkTemplate) -> [String] {
            let value = item.maximum
            var problems: [String] = []
            if value < min {
                problems.append("maximum \(value) is below \(min)")
            }
            if value > max {
                problems.append("maximum \(value) is above \(max)")
            }
            return problems
        }
    }

    final class NetworkTemplateChecksumLengthRule: NetworkTemplateRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: NetworkTemplate) -> [String] {
            let size = item.checksum.count
            if size > maxLength {
                return ["checksum is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class NetworkTemplateStartsAtRangeRule: NetworkTemplateRule {
        var min: Int
        var max: Int

        init(min: Int, max: Int) {
            self.min = min
            self.max = max
        }

        func check(_ item: NetworkTemplate) -> [String] {
            let value = item.startsAt
            if value < min || value > max {
                return ["starts at \(value) is outside \(min) to \(max)"]
            }
            return []
        }
    }

    /// Runs every rule of a network template.
    final class NetworkTemplateValidator {
        var rules: [any NetworkTemplateRule]

        init(rules: [any NetworkTemplateRule]) {
            self.rules = rules
        }

        func validate(_ item: NetworkTemplate) -> [String] {
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

        func requireValid(_ item: NetworkTemplate) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.displayLabel()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [NetworkTemplate]) -> [String: [String]] {
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

    static func defaultNetworkTemplateValidator() -> NetworkTemplateValidator {
        return NetworkTemplateValidator(
            rules: [
                NetworkTemplateMaximumRangeRule(min: 6.5, max: 263.9),
                NetworkTemplateChecksumLengthRule(maxLength: 16),
                NetworkTemplateStartsAtRangeRule(min: 64, max: 86400),
            ]
        )
    }
}
