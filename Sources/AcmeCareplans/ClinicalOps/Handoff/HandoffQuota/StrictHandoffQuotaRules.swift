import AcmePlatform
import Foundation

extension ClinicalOps {
    /// A rule a strict handoff quota must pass. Check returns its problems, or none.
    protocol StrictHandoffQuotaRule {
        func check(_ item: StrictHandoffQuota) -> [String]
    }

    final class StrictHandoffQuotaCostRangeRule: StrictHandoffQuotaRule {
        var min: Double
        var max: Double

        init(min: Double, max: Double) {
            self.min = min
            self.max = max
        }

        func check(_ item: StrictHandoffQuota) -> [String] {
            let value = item.cost
            var problems: [String] = []
            if value < min {
                problems.append("cost \(value) is below \(min)")
            }
            if value > max {
                problems.append("cost \(value) is above \(max)")
            }
            return problems
        }
    }

    final class StrictHandoffQuotaNotesLengthRule: StrictHandoffQuotaRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: StrictHandoffQuota) -> [String] {
            let size = item.notes.count
            if size > maxLength {
                return ["notes is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class StrictHandoffQuotaCodeLengthRule: StrictHandoffQuotaRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: StrictHandoffQuota) -> [String] {
            let size = item.code.count
            if size > maxLength {
                return ["code is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class StrictHandoffQuotaVersionRangeRule: StrictHandoffQuotaRule {
        var min: Int
        var max: Int

        init(min: Int, max: Int) {
            self.min = min
            self.max = max
        }

        func check(_ item: StrictHandoffQuota) -> [String] {
            let value = item.version
            var problems: [String] = []
            if value < min {
                problems.append("version \(value) is below \(min)")
            }
            if value > max {
                problems.append("version \(value) is above \(max)")
            }
            return problems
        }
    }

    final class StrictHandoffQuotaSegmentLengthRule: StrictHandoffQuotaRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: StrictHandoffQuota) -> [String] {
            let size = item.segment.count
            if size > maxLength {
                return ["segment is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class StrictHandoffQuotaNameLengthRule: StrictHandoffQuotaRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: StrictHandoffQuota) -> [String] {
            let size = item.name.count
            if size > maxLength {
                return ["name is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    /// Runs every rule of a strict handoff quota.
    final class StrictHandoffQuotaValidator {
        var rules: [any StrictHandoffQuotaRule]

        init(rules: [any StrictHandoffQuotaRule]) {
            self.rules = rules
        }

        func validate(_ item: StrictHandoffQuota) -> [String] {
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

        func requireValid(_ item: StrictHandoffQuota) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.label()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [StrictHandoffQuota]) -> [String: [String]] {
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

    static func defaultStrictHandoffQuotaValidator() -> StrictHandoffQuotaValidator {
        return StrictHandoffQuotaValidator(
            rules: [
                StrictHandoffQuotaCostRangeRule(min: 6.0, max: 4523.0),
                StrictHandoffQuotaNotesLengthRule(maxLength: 32),
                StrictHandoffQuotaCodeLengthRule(maxLength: 255),
                StrictHandoffQuotaVersionRangeRule(min: 80, max: 3600),
                StrictHandoffQuotaSegmentLengthRule(maxLength: 255),
                StrictHandoffQuotaNameLengthRule(maxLength: 86400),
            ]
        )
    }
}
