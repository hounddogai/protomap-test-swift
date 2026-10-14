import AcmePlatform
import Foundation

extension BedManagement {
    /// A rule a census audit must pass. Check returns its problems, or none.
    protocol CensusAuditRule {
        func check(_ item: CensusAudit) -> [String]
    }

    final class CensusAuditExternalRefLengthRule: CensusAuditRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: CensusAudit) -> [String] {
            let size = item.externalRef.count
            if size > maxLength {
                return ["external ref is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class CensusAuditQuantityRangeRule: CensusAuditRule {
        var min: Int
        var max: Int

        init(min: Int, max: Int) {
            self.min = min
            self.max = max
        }

        func check(_ item: CensusAudit) -> [String] {
            let value = item.quantity
            if value < min || value > max {
                return ["quantity \(value) is outside \(min) to \(max)"]
            }
            return []
        }
    }

    final class CensusAuditCountryLengthRule: CensusAuditRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: CensusAudit) -> [String] {
            let size = item.country.count
            if size > maxLength {
                return ["country is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    /// Runs every rule of a census audit.
    final class CensusAuditValidator {
        var rules: [any CensusAuditRule]

        init(rules: [any CensusAuditRule]) {
            self.rules = rules
        }

        func validate(_ item: CensusAudit) -> [String] {
            var problems: [String] = []
            for rule in rules {
                for problem in rule.check(item) {
                    problems.append(problem)
                }
            }
            return problems
        }

        func requireValid(_ item: CensusAudit) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.label()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [CensusAudit]) -> [String: [String]] {
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

    static func defaultCensusAuditValidator() -> CensusAuditValidator {
        return CensusAuditValidator(
            rules: [
                CensusAuditExternalRefLengthRule(maxLength: 255),
                CensusAuditQuantityRangeRule(min: 80, max: 255),
                CensusAuditCountryLengthRule(maxLength: 255),
            ]
        )
    }
}
