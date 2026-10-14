import AcmePlatform
import Foundation

extension Imaging {
    /// A rule a strict read baseline must pass. Check returns its problems, or none.
    protocol StrictReadBaselineRule {
        func check(_ item: StrictReadBaseline) -> [String]
    }

    final class StrictReadBaselineAllowedOwnerIDRule: StrictReadBaselineRule {
        var allowed: [String]

        init(allowed: [String]) {
            self.allowed = allowed
        }

        func check(_ item: StrictReadBaseline) -> [String] {
            if allowed.count == 0 {
                return []
            }
            if !allowed.contains(Kit.Text.normalize(item.ownerID)) {
                return ["owner id \(item.ownerID) is out of range"]
            }
            return []
        }
    }

    final class StrictReadBaselineRequiredOwnerIDRule: StrictReadBaselineRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: StrictReadBaseline) -> [String] {
            if item.ownerID.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class StrictReadBaselineNameLengthRule: StrictReadBaselineRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: StrictReadBaseline) -> [String] {
            let size = item.name.count
            if size > maxLength {
                return ["name is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class StrictReadBaselineRegionLengthRule: StrictReadBaselineRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: StrictReadBaseline) -> [String] {
            let size = item.region.count
            if size > maxLength {
                return ["region is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    /// Runs every rule of a strict read baseline.
    final class StrictReadBaselineValidator {
        var rules: [any StrictReadBaselineRule]

        init(rules: [any StrictReadBaselineRule]) {
            self.rules = rules
        }

        func validate(_ item: StrictReadBaseline) -> [String] {
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

        func requireValid(_ item: StrictReadBaseline) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.label()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [StrictReadBaseline]) -> [String: [String]] {
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

    static func defaultStrictReadBaselineValidator() -> StrictReadBaselineValidator {
        return StrictReadBaselineValidator(
            rules: [
                StrictReadBaselineAllowedOwnerIDRule(allowed: ["strict", "manual"]),
                StrictReadBaselineRequiredOwnerIDRule(message: "strict read baseline needs a value"),
                StrictReadBaselineNameLengthRule(maxLength: 120),
                StrictReadBaselineRegionLengthRule(maxLength: 120),
            ]
        )
    }
}
