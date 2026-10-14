import AcmePlatform
import Foundation

extension BedManagement {
    /// A rule a pending bed board draft must pass. Check returns its problems, or none.
    protocol PendingBedBoardDraftRule {
        func check(_ item: PendingBedBoardDraft) -> [String]
    }

    final class PendingBedBoardDraftWindowRule: PendingBedBoardDraftRule {
        var maxSpan: Int

        init(maxSpan: Int) {
            self.maxSpan = maxSpan
        }

        func check(_ item: PendingBedBoardDraft) -> [String] {
            if item.startsAt > item.endsAt {
                return ["starts at is after ends at"]
            }
            if maxSpan > 0 && (item.endsAt - item.startsAt > maxSpan) {
                return ["spans more than \(maxSpan) seconds"]
            }
            return []
        }
    }

    final class PendingBedBoardDraftCostRangeRule: PendingBedBoardDraftRule {
        var min: Double
        var max: Double

        init(min: Double, max: Double) {
            self.min = min
            self.max = max
        }

        func check(_ item: PendingBedBoardDraft) -> [String] {
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

    final class PendingBedBoardDraftSegmentLengthRule: PendingBedBoardDraftRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: PendingBedBoardDraft) -> [String] {
            let size = item.segment.count
            if size > maxLength {
                return ["segment is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class PendingBedBoardDraftWardLengthRule: PendingBedBoardDraftRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: PendingBedBoardDraft) -> [String] {
            let size = item.ward.count
            if size > maxLength {
                return ["ward is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class PendingBedBoardDraftAmountRangeRule: PendingBedBoardDraftRule {
        var min: Double
        var max: Double

        init(min: Double, max: Double) {
            self.min = min
            self.max = max
        }

        func check(_ item: PendingBedBoardDraft) -> [String] {
            let value = item.amount
            if value < min || value > max {
                return ["amount \(value) is outside \(min) to \(max)"]
            }
            return []
        }
    }

    /// Runs every rule of a pending bed board draft.
    final class PendingBedBoardDraftValidator {
        var rules: [any PendingBedBoardDraftRule]

        init(rules: [any PendingBedBoardDraftRule]) {
            self.rules = rules
        }

        func validate(_ item: PendingBedBoardDraft) -> [String] {
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

        func requireValid(_ item: PendingBedBoardDraft) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.label()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [PendingBedBoardDraft]) -> [String: [String]] {
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

    static func defaultPendingBedBoardDraftValidator() -> PendingBedBoardDraftValidator {
        return PendingBedBoardDraftValidator(
            rules: [
                PendingBedBoardDraftWindowRule(maxSpan: 1000),
                PendingBedBoardDraftCostRangeRule(min: 4.6, max: 3039.9),
                PendingBedBoardDraftSegmentLengthRule(maxLength: 64),
                PendingBedBoardDraftWardLengthRule(maxLength: 255),
                PendingBedBoardDraftAmountRangeRule(min: 2.8, max: 3866.6),
            ]
        )
    }
}
