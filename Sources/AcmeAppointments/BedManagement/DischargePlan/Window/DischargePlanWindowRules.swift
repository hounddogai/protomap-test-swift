import AcmePlatform
import Foundation

extension BedManagement {
    /// A rule a discharge plan window must pass. Check returns its problems, or none.
    protocol DischargePlanWindowRule {
        func check(_ item: DischargePlanWindow) -> [String]
    }

    final class DischargePlanWindowChecksumLengthRule: DischargePlanWindowRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: DischargePlanWindow) -> [String] {
            let size = item.checksum.count
            if size > maxLength {
                return ["checksum is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class DischargePlanWindowNameLengthRule: DischargePlanWindowRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: DischargePlanWindow) -> [String] {
            let size = item.name.count
            if size > maxLength {
                return ["name is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class DischargePlanWindowAllowedChecksumRule: DischargePlanWindowRule {
        var allowed: [String]

        init(allowed: [String]) {
            self.allowed = allowed
        }

        func check(_ item: DischargePlanWindow) -> [String] {
            if allowed.count == 0 {
                return []
            }
            if !allowed.contains(Kit.Text.normalize(item.checksum)) {
                return ["checksum \(item.checksum) is out of range"]
            }
            return []
        }
    }

    final class DischargePlanWindowDescriptionLengthRule: DischargePlanWindowRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: DischargePlanWindow) -> [String] {
            let size = item.description.count
            if size > maxLength {
                return ["description is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    /// Runs every rule of a discharge plan window.
    final class DischargePlanWindowValidator {
        var rules: [any DischargePlanWindowRule]

        init(rules: [any DischargePlanWindowRule]) {
            self.rules = rules
        }

        func validate(_ item: DischargePlanWindow) -> [String] {
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

        func requireValid(_ item: DischargePlanWindow) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.label()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [DischargePlanWindow]) -> [String: [String]] {
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

    static func defaultDischargePlanWindowValidator() -> DischargePlanWindowValidator {
        return DischargePlanWindowValidator(
            rules: [
                DischargePlanWindowChecksumLengthRule(maxLength: 1000),
                DischargePlanWindowNameLengthRule(maxLength: 64),
                DischargePlanWindowAllowedChecksumRule(allowed: ["weighted", "primary", "manual"]),
                DischargePlanWindowDescriptionLengthRule(maxLength: 86400),
            ]
        )
    }
}
