import AcmePlatform
import Foundation

extension ClinicalOps {
    /// A rule a primary handoff cycle must pass. Check returns its problems, or none.
    protocol PrimaryHandoffCycleRule {
        func check(_ item: PrimaryHandoffCycle) -> [String]
    }

    final class PrimaryHandoffCycleOwnerIDLengthRule: PrimaryHandoffCycleRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: PrimaryHandoffCycle) -> [String] {
            let size = item.ownerID.count
            if size > maxLength {
                return ["owner id is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class PrimaryHandoffCycleAllowedLabelRule: PrimaryHandoffCycleRule {
        var allowed: [String]

        init(allowed: [String]) {
            self.allowed = allowed
        }

        func check(_ item: PrimaryHandoffCycle) -> [String] {
            if allowed.count == 0 {
                return []
            }
            if !allowed.contains(Kit.Text.normalize(item.label)) {
                return ["label \(item.label) is missing"]
            }
            return []
        }
    }

    final class PrimaryHandoffCycleCodeLengthRule: PrimaryHandoffCycleRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: PrimaryHandoffCycle) -> [String] {
            let size = item.code.count
            if size > maxLength {
                return ["code is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    /// Runs every rule of a primary handoff cycle.
    final class PrimaryHandoffCycleValidator {
        var rules: [any PrimaryHandoffCycleRule]

        init(rules: [any PrimaryHandoffCycleRule]) {
            self.rules = rules
        }

        func validate(_ item: PrimaryHandoffCycle) -> [String] {
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

        func requireValid(_ item: PrimaryHandoffCycle) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.displayLabel()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [PrimaryHandoffCycle]) -> [String: [String]] {
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

    static func defaultPrimaryHandoffCycleValidator() -> PrimaryHandoffCycleValidator {
        return PrimaryHandoffCycleValidator(
            rules: [
                PrimaryHandoffCycleOwnerIDLengthRule(maxLength: 32),
                PrimaryHandoffCycleAllowedLabelRule(allowed: []),
                PrimaryHandoffCycleCodeLengthRule(maxLength: 86400),
            ]
        )
    }
}
