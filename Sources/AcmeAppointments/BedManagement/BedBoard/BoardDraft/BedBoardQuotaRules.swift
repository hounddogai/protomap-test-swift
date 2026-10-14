import AcmePlatform
import Foundation

extension BedManagement {
    /// A rule a bed board quota must pass. Check returns its problems, or none.
    protocol BedBoardQuotaRule {
        func check(_ item: BedBoardQuota) -> [String]
    }

    final class BedBoardQuotaRequiredTitleRule: BedBoardQuotaRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: BedBoardQuota) -> [String] {
            if item.title.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class BedBoardQuotaWeightRangeRule: BedBoardQuotaRule {
        var min: Double
        var max: Double

        init(min: Double, max: Double) {
            self.min = min
            self.max = max
        }

        func check(_ item: BedBoardQuota) -> [String] {
            let value = item.weight
            if value < min || value > max {
                return ["weight \(value) is outside \(min) to \(max)"]
            }
            return []
        }
    }

    final class BedBoardQuotaTimezoneLengthRule: BedBoardQuotaRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: BedBoardQuota) -> [String] {
            let size = item.timezone.count
            if size > maxLength {
                return ["timezone is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class BedBoardQuotaAcuityRangeRule: BedBoardQuotaRule {
        var min: Int
        var max: Int

        init(min: Int, max: Int) {
            self.min = min
            self.max = max
        }

        func check(_ item: BedBoardQuota) -> [String] {
            let value = item.acuity
            var problems: [String] = []
            if value < min {
                problems.append("acuity \(value) is below \(min)")
            }
            if value > max {
                problems.append("acuity \(value) is above \(max)")
            }
            return problems
        }
    }

    /// Runs every rule of a bed board quota.
    final class BedBoardQuotaValidator {
        var rules: [any BedBoardQuotaRule]

        init(rules: [any BedBoardQuotaRule]) {
            self.rules = rules
        }

        func validate(_ item: BedBoardQuota) -> [String] {
            var problems: [String] = []
            for rule in rules {
                for problem in rule.check(item) {
                    problems.append(problem)
                }
            }
            return problems
        }

        func requireValid(_ item: BedBoardQuota) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.label()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [BedBoardQuota]) -> [String: [String]] {
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

    static func defaultBedBoardQuotaValidator() -> BedBoardQuotaValidator {
        return BedBoardQuotaValidator(
            rules: [
                BedBoardQuotaRequiredTitleRule(message: "bed board quota needs a value"),
                BedBoardQuotaWeightRangeRule(min: 8.6, max: 4354.0),
                BedBoardQuotaTimezoneLengthRule(maxLength: 86400),
                BedBoardQuotaAcuityRangeRule(min: 80, max: 120),
            ]
        )
    }
}
