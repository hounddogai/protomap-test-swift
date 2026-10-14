import AcmePlatform
import Foundation

extension Labs {
    /// A rule a adaptive panel snapshot must pass. Check returns its problems, or none.
    protocol AdaptivePanelSnapshotRule {
        func check(_ item: AdaptivePanelSnapshot) -> [String]
    }

    final class AdaptivePanelSnapshotRatioRangeRule: AdaptivePanelSnapshotRule {
        var min: Double
        var max: Double

        init(min: Double, max: Double) {
            self.min = min
            self.max = max
        }

        func check(_ item: AdaptivePanelSnapshot) -> [String] {
            let value = item.ratio
            if value < min || value > max {
                return ["ratio \(value) is outside \(min) to \(max)"]
            }
            return []
        }
    }

    final class AdaptivePanelSnapshotUpdatedAtRangeRule: AdaptivePanelSnapshotRule {
        var min: Int
        var max: Int

        init(min: Int, max: Int) {
            self.min = min
            self.max = max
        }

        func check(_ item: AdaptivePanelSnapshot) -> [String] {
            let value = item.updatedAt
            if value < min || value > max {
                return ["updated at \(value) is outside \(min) to \(max)"]
            }
            return []
        }
    }

    final class AdaptivePanelSnapshotChannelLengthRule: AdaptivePanelSnapshotRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: AdaptivePanelSnapshot) -> [String] {
            let size = item.channel.count
            if size > maxLength {
                return ["channel is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class AdaptivePanelSnapshotBudgetRangeRule: AdaptivePanelSnapshotRule {
        var min: Double
        var max: Double

        init(min: Double, max: Double) {
            self.min = min
            self.max = max
        }

        func check(_ item: AdaptivePanelSnapshot) -> [String] {
            let value = item.budget
            if value < min || value > max {
                return ["budget \(value) is outside \(min) to \(max)"]
            }
            return []
        }
    }

    /// Runs every rule of a adaptive panel snapshot.
    final class AdaptivePanelSnapshotValidator {
        var rules: [any AdaptivePanelSnapshotRule]

        init(rules: [any AdaptivePanelSnapshotRule]) {
            self.rules = rules
        }

        func validate(_ item: AdaptivePanelSnapshot) -> [String] {
            var problems: [String] = []
            for rule in rules {
                for problem in rule.check(item) {
                    problems.append(problem)
                }
            }
            return problems
        }

        func requireValid(_ item: AdaptivePanelSnapshot) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.displayLabel()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [AdaptivePanelSnapshot]) -> [String: [String]] {
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

    static func defaultAdaptivePanelSnapshotValidator() -> AdaptivePanelSnapshotValidator {
        return AdaptivePanelSnapshotValidator(
            rules: [
                AdaptivePanelSnapshotRatioRangeRule(min: 0.6, max: 843.9),
                AdaptivePanelSnapshotUpdatedAtRangeRule(min: 255, max: 255),
                AdaptivePanelSnapshotChannelLengthRule(maxLength: 80),
                AdaptivePanelSnapshotBudgetRangeRule(min: 3.9, max: 4988.8),
            ]
        )
    }
}
