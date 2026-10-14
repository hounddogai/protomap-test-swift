import AcmePlatform
import Foundation

extension CareManagement {
    /// A rule a care gap checkpoint must pass. Check returns its problems, or none.
    protocol CareGapCheckpointRule {
        func check(_ item: CareGapCheckpoint) -> [String]
    }

    final class CareGapCheckpointCodeLengthRule: CareGapCheckpointRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: CareGapCheckpoint) -> [String] {
            let size = item.code.count
            if size > maxLength {
                return ["code is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class CareGapCheckpointRequiredOwnerIDRule: CareGapCheckpointRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: CareGapCheckpoint) -> [String] {
            if item.ownerID.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class CareGapCheckpointEndsAtRangeRule: CareGapCheckpointRule {
        var min: Int
        var max: Int

        init(min: Int, max: Int) {
            self.min = min
            self.max = max
        }

        func check(_ item: CareGapCheckpoint) -> [String] {
            let value = item.endsAt
            if value < min || value > max {
                return ["ends at \(value) is outside \(min) to \(max)"]
            }
            return []
        }
    }

    final class CareGapCheckpointDiscountRangeRule: CareGapCheckpointRule {
        var min: Double
        var max: Double

        init(min: Double, max: Double) {
            self.min = min
            self.max = max
        }

        func check(_ item: CareGapCheckpoint) -> [String] {
            let value = item.discount
            if value < min || value > max {
                return ["discount \(value) is outside \(min) to \(max)"]
            }
            return []
        }
    }

    /// Runs every rule of a care gap checkpoint.
    final class CareGapCheckpointValidator {
        var rules: [any CareGapCheckpointRule]

        init(rules: [any CareGapCheckpointRule]) {
            self.rules = rules
        }

        func validate(_ item: CareGapCheckpoint) -> [String] {
            var problems: [String] = []
            for rule in rules {
                for problem in rule.check(item) {
                    problems.append(problem)
                }
            }
            return problems
        }

        func requireValid(_ item: CareGapCheckpoint) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.label()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [CareGapCheckpoint]) -> [String: [String]] {
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

    static func defaultCareGapCheckpointValidator() -> CareGapCheckpointValidator {
        return CareGapCheckpointValidator(
            rules: [
                CareGapCheckpointCodeLengthRule(maxLength: 3600),
                CareGapCheckpointRequiredOwnerIDRule(message: "care gap checkpoint needs this field"),
                CareGapCheckpointEndsAtRangeRule(min: 120, max: 1000),
                CareGapCheckpointDiscountRangeRule(min: 4.0, max: 1033.1),
            ]
        )
    }
}
