import AcmePlatform
import Foundation

extension Labs {
    /// A rule a specimen window must pass. Check returns its problems, or none.
    protocol SpecimenWindowRule {
        func check(_ item: SpecimenWindow) -> [String]
    }

    final class SpecimenWindowRequiredChecksumRule: SpecimenWindowRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: SpecimenWindow) -> [String] {
            if item.checksum.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class SpecimenWindowQuantityRangeRule: SpecimenWindowRule {
        var min: Int
        var max: Int

        init(min: Int, max: Int) {
            self.min = min
            self.max = max
        }

        func check(_ item: SpecimenWindow) -> [String] {
            let value = item.quantity
            if value < min || value > max {
                return ["quantity \(value) is outside \(min) to \(max)"]
            }
            return []
        }
    }

    final class SpecimenWindowAllowedTitleRule: SpecimenWindowRule {
        var allowed: [String]

        init(allowed: [String]) {
            self.allowed = allowed
        }

        func check(_ item: SpecimenWindow) -> [String] {
            if allowed.count == 0 {
                return []
            }
            if !allowed.contains(Kit.Text.normalize(item.title)) {
                return ["title \(item.title) is not allowed"]
            }
            return []
        }
    }

    final class SpecimenWindowRequiredTitleRule: SpecimenWindowRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: SpecimenWindow) -> [String] {
            if item.title.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    /// Runs every rule of a specimen window.
    final class SpecimenWindowValidator {
        var rules: [any SpecimenWindowRule]

        init(rules: [any SpecimenWindowRule]) {
            self.rules = rules
        }

        func validate(_ item: SpecimenWindow) -> [String] {
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

        func requireValid(_ item: SpecimenWindow) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.label()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [SpecimenWindow]) -> [String: [String]] {
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

    static func defaultSpecimenWindowValidator() -> SpecimenWindowValidator {
        return SpecimenWindowValidator(
            rules: [
                SpecimenWindowRequiredChecksumRule(message: "specimen window needs an entry"),
                SpecimenWindowQuantityRangeRule(min: 1000, max: 86400),
                SpecimenWindowAllowedTitleRule(allowed: ["rolling"]),
                SpecimenWindowRequiredTitleRule(message: "specimen window needs this field"),
            ]
        )
    }
}
