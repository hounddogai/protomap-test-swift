import AcmePlatform
import Foundation

extension Pharmacy {
    /// A rule a capped recall bundle must pass. Check returns its problems, or none.
    protocol CappedRecallBundleRule {
        func check(_ item: CappedRecallBundle) -> [String]
    }

    final class CappedRecallBundleRetriesRangeRule: CappedRecallBundleRule {
        var min: Int
        var max: Int

        init(min: Int, max: Int) {
            self.min = min
            self.max = max
        }

        func check(_ item: CappedRecallBundle) -> [String] {
            let value = item.retries
            var problems: [String] = []
            if value < min {
                problems.append("retries \(value) is below \(min)")
            }
            if value > max {
                problems.append("retries \(value) is above \(max)")
            }
            return problems
        }
    }

    final class CappedRecallBundleEncounterIDLengthRule: CappedRecallBundleRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: CappedRecallBundle) -> [String] {
            let size = item.encounterID.count
            if size > maxLength {
                return ["encounter id is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class CappedRecallBundleApprovedGuardRule: CappedRecallBundleRule {
        var limit: Int

        init(limit: Int) {
            self.limit = limit
        }

        func check(_ item: CappedRecallBundle) -> [String] {
            if item.approved && (item.retries > limit) {
                return ["retries \(item.retries) exceeds \(limit) while approved"]
            }
            return []
        }
    }

    /// Runs every rule of a capped recall bundle.
    final class CappedRecallBundleValidator {
        var rules: [any CappedRecallBundleRule]

        init(rules: [any CappedRecallBundleRule]) {
            self.rules = rules
        }

        func validate(_ item: CappedRecallBundle) -> [String] {
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

        func requireValid(_ item: CappedRecallBundle) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.label()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [CappedRecallBundle]) -> [String: [String]] {
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

    static func defaultCappedRecallBundleValidator() -> CappedRecallBundleValidator {
        return CappedRecallBundleValidator(
            rules: [
                CappedRecallBundleRetriesRangeRule(min: 16, max: 3600),
                CappedRecallBundleEncounterIDLengthRule(maxLength: 32),
                CappedRecallBundleApprovedGuardRule(limit: 64),
            ]
        )
    }
}
