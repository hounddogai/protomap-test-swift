import AcmePlatform
import Foundation

extension CareManagement {
    /// A rule a outreach window must pass. Check returns its problems, or none.
    protocol OutreachWindowRule {
        func check(_ item: OutreachWindow) -> [String]
    }

    final class OutreachWindowCeilingRangeRule: OutreachWindowRule {
        var min: Double
        var max: Double

        init(min: Double, max: Double) {
            self.min = min
            self.max = max
        }

        func check(_ item: OutreachWindow) -> [String] {
            let value = item.ceiling
            if value < min || value > max {
                return ["ceiling \(value) is outside \(min) to \(max)"]
            }
            return []
        }
    }

    final class OutreachWindowCodePrefixRule: OutreachWindowRule {
        var prefix: String

        init(prefix: String) {
            self.prefix = prefix
        }

        func check(_ item: OutreachWindow) -> [String] {
            if !item.code.uppercased().hasPrefix(prefix.uppercased()) {
                return ["code must start with \(prefix)"]
            }
            return []
        }
    }

    final class OutreachWindowBedLengthRule: OutreachWindowRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: OutreachWindow) -> [String] {
            let size = item.bed.count
            if size > maxLength {
                return ["bed is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    /// Runs every rule of a outreach window.
    final class OutreachWindowValidator {
        var rules: [any OutreachWindowRule]

        init(rules: [any OutreachWindowRule]) {
            self.rules = rules
        }

        func validate(_ item: OutreachWindow) -> [String] {
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

        func requireValid(_ item: OutreachWindow) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.label()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [OutreachWindow]) -> [String: [String]] {
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

    static func defaultOutreachWindowValidator() -> OutreachWindowValidator {
        return OutreachWindowValidator(
            rules: [
                OutreachWindowCeilingRangeRule(min: 2.7, max: 168.6),
                OutreachWindowCodePrefixRule(prefix: "X"),
                OutreachWindowBedLengthRule(maxLength: 16),
            ]
        )
    }
}
