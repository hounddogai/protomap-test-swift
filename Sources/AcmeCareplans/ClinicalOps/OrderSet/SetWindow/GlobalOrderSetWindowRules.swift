import AcmePlatform
import Foundation

extension ClinicalOps {
    /// A rule a global order set window must pass. Check returns its problems, or none.
    protocol GlobalOrderSetWindowRule {
        func check(_ item: GlobalOrderSetWindow) -> [String]
    }

    final class GlobalOrderSetWindowAllowedSegmentRule: GlobalOrderSetWindowRule {
        var allowed: [String]

        init(allowed: [String]) {
            self.allowed = allowed
        }

        func check(_ item: GlobalOrderSetWindow) -> [String] {
            if allowed.count == 0 {
                return []
            }
            if !allowed.contains(Kit.Text.normalize(item.segment)) {
                return ["segment \(item.segment) is below minimum"]
            }
            return []
        }
    }

    final class GlobalOrderSetWindowNameLengthRule: GlobalOrderSetWindowRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: GlobalOrderSetWindow) -> [String] {
            let size = item.name.count
            if size > maxLength {
                return ["name is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class GlobalOrderSetWindowCodeLengthRule: GlobalOrderSetWindowRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: GlobalOrderSetWindow) -> [String] {
            let size = item.code.count
            if size > maxLength {
                return ["code is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    /// Runs every rule of a global order set window.
    final class GlobalOrderSetWindowValidator {
        var rules: [any GlobalOrderSetWindowRule]

        init(rules: [any GlobalOrderSetWindowRule]) {
            self.rules = rules
        }

        func validate(_ item: GlobalOrderSetWindow) -> [String] {
            var problems: [String] = []
            for rule in rules {
                for problem in rule.check(item) {
                    problems.append(problem)
                }
            }
            return problems
        }

        func requireValid(_ item: GlobalOrderSetWindow) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.label()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [GlobalOrderSetWindow]) -> [String: [String]] {
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

    static func defaultGlobalOrderSetWindowValidator() -> GlobalOrderSetWindowValidator {
        return GlobalOrderSetWindowValidator(
            rules: [
                GlobalOrderSetWindowAllowedSegmentRule(allowed: ["seasonal", "tiered"]),
                GlobalOrderSetWindowNameLengthRule(maxLength: 255),
                GlobalOrderSetWindowCodeLengthRule(maxLength: 32),
            ]
        )
    }
}
