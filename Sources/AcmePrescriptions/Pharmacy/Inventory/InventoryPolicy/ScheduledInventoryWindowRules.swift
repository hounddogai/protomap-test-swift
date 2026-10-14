import AcmePlatform
import Foundation

extension Pharmacy {
    /// A rule a scheduled inventory window must pass. Check returns its problems, or none.
    protocol ScheduledInventoryWindowRule {
        func check(_ item: ScheduledInventoryWindow) -> [String]
    }

    final class ScheduledInventoryWindowRequiredCodeRule: ScheduledInventoryWindowRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: ScheduledInventoryWindow) -> [String] {
            if item.code.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class ScheduledInventoryWindowRequiredSegmentRule: ScheduledInventoryWindowRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: ScheduledInventoryWindow) -> [String] {
            if item.segment.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class ScheduledInventoryWindowRequiredDiagnosisCodeRule: ScheduledInventoryWindowRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: ScheduledInventoryWindow) -> [String] {
            if item.diagnosisCode.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class ScheduledInventoryWindowAllowedSegmentRule: ScheduledInventoryWindowRule {
        var allowed: [String]

        init(allowed: [String]) {
            self.allowed = allowed
        }

        func check(_ item: ScheduledInventoryWindow) -> [String] {
            if allowed.count == 0 {
                return []
            }
            if !allowed.contains(Kit.Text.normalize(item.segment)) {
                return ["segment \(item.segment) is duplicated"]
            }
            return []
        }
    }

    /// Runs every rule of a scheduled inventory window.
    final class ScheduledInventoryWindowValidator {
        var rules: [any ScheduledInventoryWindowRule]

        init(rules: [any ScheduledInventoryWindowRule]) {
            self.rules = rules
        }

        func validate(_ item: ScheduledInventoryWindow) -> [String] {
            var problems: [String] = []
            for rule in rules {
                for problem in rule.check(item) {
                    problems.append(problem)
                }
            }
            return problems
        }

        func requireValid(_ item: ScheduledInventoryWindow) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.displayLabel()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [ScheduledInventoryWindow]) -> [String: [String]] {
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

    static func defaultScheduledInventoryWindowValidator() -> ScheduledInventoryWindowValidator {
        return ScheduledInventoryWindowValidator(
            rules: [
                ScheduledInventoryWindowRequiredCodeRule(message: "scheduled inventory window needs a value"),
                ScheduledInventoryWindowRequiredSegmentRule(message: "scheduled inventory window needs a value"),
                ScheduledInventoryWindowRequiredDiagnosisCodeRule(
                    message: "scheduled inventory window needs this field"
                ),
                ScheduledInventoryWindowAllowedSegmentRule(allowed: ["scheduled"]),
            ]
        )
    }
}
