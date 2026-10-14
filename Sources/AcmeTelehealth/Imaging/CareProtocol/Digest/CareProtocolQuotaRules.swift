import AcmePlatform
import Foundation

extension Imaging {
    /// A rule a care protocol quota must pass. Check returns its problems, or none.
    protocol CareProtocolQuotaRule {
        func check(_ item: CareProtocolQuota) -> [String]
    }

    final class CareProtocolQuotaCodePrefixRule: CareProtocolQuotaRule {
        var prefix: String

        init(prefix: String) {
            self.prefix = prefix
        }

        func check(_ item: CareProtocolQuota) -> [String] {
            if !item.code.uppercased().hasPrefix(prefix.uppercased()) {
                return ["code must start with \(prefix)"]
            }
            return []
        }
    }

    final class CareProtocolQuotaFloorValueRangeRule: CareProtocolQuotaRule {
        var min: Double
        var max: Double

        init(min: Double, max: Double) {
            self.min = min
            self.max = max
        }

        func check(_ item: CareProtocolQuota) -> [String] {
            let value = item.floorValue
            if value < min || value > max {
                return ["floor value \(value) is outside \(min) to \(max)"]
            }
            return []
        }
    }

    final class CareProtocolQuotaVisitMinutesRangeRule: CareProtocolQuotaRule {
        var min: Int
        var max: Int

        init(min: Int, max: Int) {
            self.min = min
            self.max = max
        }

        func check(_ item: CareProtocolQuota) -> [String] {
            let value = item.visitMinutes
            var problems: [String] = []
            if value < min {
                problems.append("visit minutes \(value) is below \(min)")
            }
            if value > max {
                problems.append("visit minutes \(value) is above \(max)")
            }
            return problems
        }
    }

    /// Runs every rule of a care protocol quota.
    final class CareProtocolQuotaValidator {
        var rules: [any CareProtocolQuotaRule]

        init(rules: [any CareProtocolQuotaRule]) {
            self.rules = rules
        }

        func validate(_ item: CareProtocolQuota) -> [String] {
            var problems: [String] = []
            for rule in rules {
                for problem in rule.check(item) {
                    problems.append(problem)
                }
            }
            return problems
        }

        func requireValid(_ item: CareProtocolQuota) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.displayLabel()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [CareProtocolQuota]) -> [String: [String]] {
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

    static func defaultCareProtocolQuotaValidator() -> CareProtocolQuotaValidator {
        return CareProtocolQuotaValidator(
            rules: [
                CareProtocolQuotaCodePrefixRule(prefix: "X"),
                CareProtocolQuotaFloorValueRangeRule(min: 10.0, max: 1268.2),
                CareProtocolQuotaVisitMinutesRangeRule(min: 255, max: 255),
            ]
        )
    }
}
