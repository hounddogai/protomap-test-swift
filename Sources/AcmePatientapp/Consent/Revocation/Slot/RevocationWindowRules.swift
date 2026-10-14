import AcmePlatform
import Foundation

extension Consent {
    /// A rule a revocation window must pass. Check returns its problems, or none.
    protocol RevocationWindowRule {
        func check(_ item: RevocationWindow) -> [String]
    }

    final class RevocationWindowCodeLengthRule: RevocationWindowRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: RevocationWindow) -> [String] {
            let size = item.code.count
            if size > maxLength {
                return ["code is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class RevocationWindowPayerLengthRule: RevocationWindowRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: RevocationWindow) -> [String] {
            let size = item.payer.count
            if size > maxLength {
                return ["payer is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class RevocationWindowRequiredSegmentRule: RevocationWindowRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: RevocationWindow) -> [String] {
            if item.segment.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class RevocationWindowCeilingRangeRule: RevocationWindowRule {
        var min: Double
        var max: Double

        init(min: Double, max: Double) {
            self.min = min
            self.max = max
        }

        func check(_ item: RevocationWindow) -> [String] {
            let value = item.ceiling
            var problems: [String] = []
            if value < min {
                problems.append("ceiling \(value) is below \(min)")
            }
            if value > max {
                problems.append("ceiling \(value) is above \(max)")
            }
            return problems
        }
    }

    /// Runs every rule of a revocation window.
    final class RevocationWindowValidator {
        var rules: [any RevocationWindowRule]

        init(rules: [any RevocationWindowRule]) {
            self.rules = rules
        }

        func validate(_ item: RevocationWindow) -> [String] {
            var problems: [String] = []
            for rule in rules {
                for problem in rule.check(item) {
                    problems.append(problem)
                }
            }
            return problems
        }

        func requireValid(_ item: RevocationWindow) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.label()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [RevocationWindow]) -> [String: [String]] {
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

    static func defaultRevocationWindowValidator() -> RevocationWindowValidator {
        return RevocationWindowValidator(
            rules: [
                RevocationWindowCodeLengthRule(maxLength: 86400),
                RevocationWindowPayerLengthRule(maxLength: 80),
                RevocationWindowRequiredSegmentRule(message: "revocation window needs an entry"),
                RevocationWindowCeilingRangeRule(min: 6.9, max: 2347.4),
            ]
        )
    }
}
