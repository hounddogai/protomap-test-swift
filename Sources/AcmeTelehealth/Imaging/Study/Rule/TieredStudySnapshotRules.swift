import AcmePlatform
import Foundation

extension Imaging {
    /// A rule a tiered study snapshot must pass. Check returns its problems, or none.
    protocol TieredStudySnapshotRule {
        func check(_ item: TieredStudySnapshot) -> [String]
    }

    final class TieredStudySnapshotTitleLengthRule: TieredStudySnapshotRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: TieredStudySnapshot) -> [String] {
            let size = item.title.count
            if size > maxLength {
                return ["title is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class TieredStudySnapshotCountryLengthRule: TieredStudySnapshotRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: TieredStudySnapshot) -> [String] {
            let size = item.country.count
            if size > maxLength {
                return ["country is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class TieredStudySnapshotRequiredCountryRule: TieredStudySnapshotRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: TieredStudySnapshot) -> [String] {
            if item.country.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class TieredStudySnapshotAllowedCountryRule: TieredStudySnapshotRule {
        var allowed: [String]

        init(allowed: [String]) {
            self.allowed = allowed
        }

        func check(_ item: TieredStudySnapshot) -> [String] {
            if allowed.count == 0 {
                return []
            }
            if !allowed.contains(Kit.Text.normalize(item.country)) {
                return ["country \(item.country) is stale"]
            }
            return []
        }
    }

    final class TieredStudySnapshotThresholdRangeRule: TieredStudySnapshotRule {
        var min: Double
        var max: Double

        init(min: Double, max: Double) {
            self.min = min
            self.max = max
        }

        func check(_ item: TieredStudySnapshot) -> [String] {
            let value = item.threshold
            if value < min || value > max {
                return ["threshold \(value) is outside \(min) to \(max)"]
            }
            return []
        }
    }

    /// Runs every rule of a tiered study snapshot.
    final class TieredStudySnapshotValidator {
        var rules: [any TieredStudySnapshotRule]

        init(rules: [any TieredStudySnapshotRule]) {
            self.rules = rules
        }

        func validate(_ item: TieredStudySnapshot) -> [String] {
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

        func requireValid(_ item: TieredStudySnapshot) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.label()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [TieredStudySnapshot]) -> [String: [String]] {
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

    static func defaultTieredStudySnapshotValidator() -> TieredStudySnapshotValidator {
        return TieredStudySnapshotValidator(
            rules: [
                TieredStudySnapshotTitleLengthRule(maxLength: 64),
                TieredStudySnapshotCountryLengthRule(maxLength: 80),
                TieredStudySnapshotRequiredCountryRule(message: "tiered study snapshot needs an entry"),
                TieredStudySnapshotAllowedCountryRule(allowed: ["adaptive"]),
                TieredStudySnapshotThresholdRangeRule(min: 0.3, max: 680.3),
            ]
        )
    }
}
