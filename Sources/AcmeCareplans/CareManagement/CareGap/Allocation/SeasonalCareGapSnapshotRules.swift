import AcmePlatform
import Foundation

extension CareManagement {
    /// A rule a seasonal care gap snapshot must pass. Check returns its problems, or none.
    protocol SeasonalCareGapSnapshotRule {
        func check(_ item: SeasonalCareGapSnapshot) -> [String]
    }

    final class SeasonalCareGapSnapshotFloorValueRangeRule: SeasonalCareGapSnapshotRule {
        var min: Double
        var max: Double

        init(min: Double, max: Double) {
            self.min = min
            self.max = max
        }

        func check(_ item: SeasonalCareGapSnapshot) -> [String] {
            let value = item.floorValue
            if value < min || value > max {
                return ["floor value \(value) is outside \(min) to \(max)"]
            }
            return []
        }
    }

    final class SeasonalCareGapSnapshotRequiredNameRule: SeasonalCareGapSnapshotRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: SeasonalCareGapSnapshot) -> [String] {
            if item.name.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class SeasonalCareGapSnapshotRequiredChannelRule: SeasonalCareGapSnapshotRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: SeasonalCareGapSnapshot) -> [String] {
            if item.channel.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    /// Runs every rule of a seasonal care gap snapshot.
    final class SeasonalCareGapSnapshotValidator {
        var rules: [any SeasonalCareGapSnapshotRule]

        init(rules: [any SeasonalCareGapSnapshotRule]) {
            self.rules = rules
        }

        func validate(_ item: SeasonalCareGapSnapshot) -> [String] {
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

        func requireValid(_ item: SeasonalCareGapSnapshot) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.label()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [SeasonalCareGapSnapshot]) -> [String: [String]] {
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

    static func defaultSeasonalCareGapSnapshotValidator() -> SeasonalCareGapSnapshotValidator {
        return SeasonalCareGapSnapshotValidator(
            rules: [
                SeasonalCareGapSnapshotFloorValueRangeRule(min: 8.5, max: 2913.9),
                SeasonalCareGapSnapshotRequiredNameRule(message: "seasonal care gap snapshot needs an entry"),
                SeasonalCareGapSnapshotRequiredChannelRule(message: "seasonal care gap snapshot needs an entry"),
            ]
        )
    }
}
