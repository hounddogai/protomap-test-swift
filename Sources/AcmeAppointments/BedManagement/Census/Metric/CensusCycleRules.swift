import AcmePlatform
import Foundation

extension BedManagement {
    /// A rule a census cycle must pass. Check returns its problems, or none.
    protocol CensusCycleRule {
        func check(_ item: CensusCycle) -> [String]
    }

    final class CensusCycleOwnerIDLengthRule: CensusCycleRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: CensusCycle) -> [String] {
            let size = item.ownerID.count
            if size > maxLength {
                return ["owner id is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class CensusCycleCodePrefixRule: CensusCycleRule {
        var prefix: String

        init(prefix: String) {
            self.prefix = prefix
        }

        func check(_ item: CensusCycle) -> [String] {
            if !item.code.uppercased().hasPrefix(prefix.uppercased()) {
                return ["code must start with \(prefix)"]
            }
            return []
        }
    }

    final class CensusCycleDosageMgRangeRule: CensusCycleRule {
        var min: Double
        var max: Double

        init(min: Double, max: Double) {
            self.min = min
            self.max = max
        }

        func check(_ item: CensusCycle) -> [String] {
            let value = item.dosageMg
            if value < min || value > max {
                return ["dosage mg \(value) is outside \(min) to \(max)"]
            }
            return []
        }
    }

    final class CensusCycleAllowedOwnerIDRule: CensusCycleRule {
        var allowed: [String]

        init(allowed: [String]) {
            self.allowed = allowed
        }

        func check(_ item: CensusCycle) -> [String] {
            if allowed.count == 0 {
                return []
            }
            if !allowed.contains(Kit.Text.normalize(item.ownerID)) {
                return ["owner id \(item.ownerID) is missing"]
            }
            return []
        }
    }

    /// Runs every rule of a census cycle.
    final class CensusCycleValidator {
        var rules: [any CensusCycleRule]

        init(rules: [any CensusCycleRule]) {
            self.rules = rules
        }

        func validate(_ item: CensusCycle) -> [String] {
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

        func requireValid(_ item: CensusCycle) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.displayLabel()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [CensusCycle]) -> [String: [String]] {
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

    static func defaultCensusCycleValidator() -> CensusCycleValidator {
        return CensusCycleValidator(
            rules: [
                CensusCycleOwnerIDLengthRule(maxLength: 64),
                CensusCycleCodePrefixRule(prefix: "Q"),
                CensusCycleDosageMgRangeRule(min: 1.5, max: 1680.5),
                CensusCycleAllowedOwnerIDRule(allowed: []),
            ]
        )
    }
}
