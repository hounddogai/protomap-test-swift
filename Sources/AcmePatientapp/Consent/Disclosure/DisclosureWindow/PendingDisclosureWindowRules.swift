import AcmePlatform
import Foundation

extension Consent {
    /// A rule a pending disclosure window must pass. Check returns its problems, or none.
    protocol PendingDisclosureWindowRule {
        func check(_ item: PendingDisclosureWindow) -> [String]
    }

    final class PendingDisclosureWindowMarginRangeRule: PendingDisclosureWindowRule {
        var min: Double
        var max: Double

        init(min: Double, max: Double) {
            self.min = min
            self.max = max
        }

        func check(_ item: PendingDisclosureWindow) -> [String] {
            let value = item.margin
            var problems: [String] = []
            if value < min {
                problems.append("margin \(value) is below \(min)")
            }
            if value > max {
                problems.append("margin \(value) is above \(max)")
            }
            return problems
        }
    }

    final class PendingDisclosureWindowGraceDaysRangeRule: PendingDisclosureWindowRule {
        var min: Int
        var max: Int

        init(min: Int, max: Int) {
            self.min = min
            self.max = max
        }

        func check(_ item: PendingDisclosureWindow) -> [String] {
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

    final class PendingDisclosureWindowCodeLengthRule: PendingDisclosureWindowRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: PendingDisclosureWindow) -> [String] {
            let size = item.code.count
            if size > maxLength {
                return ["code is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class PendingDisclosureWindowAllowedNameRule: PendingDisclosureWindowRule {
        var allowed: [String]

        init(allowed: [String]) {
            self.allowed = allowed
        }

        func check(_ item: PendingDisclosureWindow) -> [String] {
            if allowed.count == 0 {
                return []
            }
            if !allowed.contains(Kit.Text.normalize(item.name)) {
                return ["name \(item.name) is too long"]
            }
            return []
        }
    }

    /// Runs every rule of a pending disclosure window.
    final class PendingDisclosureWindowValidator {
        var rules: [any PendingDisclosureWindowRule]

        init(rules: [any PendingDisclosureWindowRule]) {
            self.rules = rules
        }

        func validate(_ item: PendingDisclosureWindow) -> [String] {
            var problems: [String] = []
            for rule in rules {
                for problem in rule.check(item) {
                    problems.append(problem)
                }
            }
            return problems
        }

        func requireValid(_ item: PendingDisclosureWindow) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.label()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [PendingDisclosureWindow]) -> [String: [String]] {
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

    static func defaultPendingDisclosureWindowValidator() -> PendingDisclosureWindowValidator {
        return PendingDisclosureWindowValidator(
            rules: [
                PendingDisclosureWindowMarginRangeRule(min: 1.4, max: 2222.1),
                PendingDisclosureWindowGraceDaysRangeRule(min: 16, max: 86400),
                PendingDisclosureWindowCodeLengthRule(maxLength: 86400),
                PendingDisclosureWindowAllowedNameRule(allowed: ["primary", "strict", "tiered"]),
            ]
        )
    }
}
