import AcmePlatform
import Foundation

extension BedManagement {
    /// A rule a global isolation request must pass. Check returns its problems, or none.
    protocol GlobalIsolationRequestRule {
        func check(_ item: GlobalIsolationRequest) -> [String]
    }

    final class GlobalIsolationRequestRegionLengthRule: GlobalIsolationRequestRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: GlobalIsolationRequest) -> [String] {
            let size = item.region.count
            if size > maxLength {
                return ["region is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class GlobalIsolationRequestRateRangeRule: GlobalIsolationRequestRule {
        var min: Double
        var max: Double

        init(min: Double, max: Double) {
            self.min = min
            self.max = max
        }

        func check(_ item: GlobalIsolationRequest) -> [String] {
            let value = item.rate
            var problems: [String] = []
            if value < min {
                problems.append("rate \(value) is below \(min)")
            }
            if value > max {
                problems.append("rate \(value) is above \(max)")
            }
            return problems
        }
    }

    final class GlobalIsolationRequestRequiredSourceRule: GlobalIsolationRequestRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: GlobalIsolationRequest) -> [String] {
            if item.source.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class GlobalIsolationRequestRequiredCodeRule: GlobalIsolationRequestRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: GlobalIsolationRequest) -> [String] {
            if item.code.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class GlobalIsolationRequestTitleLengthRule: GlobalIsolationRequestRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: GlobalIsolationRequest) -> [String] {
            let size = item.title.count
            if size > maxLength {
                return ["title is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class GlobalIsolationRequestActiveGuardRule: GlobalIsolationRequestRule {
        var limit: Double

        init(limit: Double) {
            self.limit = limit
        }

        func check(_ item: GlobalIsolationRequest) -> [String] {
            if item.active && (item.rate > limit) {
                return ["rate \(item.rate) exceeds \(limit) while active"]
            }
            return []
        }
    }

    /// Runs every rule of a global isolation request.
    final class GlobalIsolationRequestValidator {
        var rules: [any GlobalIsolationRequestRule]

        init(rules: [any GlobalIsolationRequestRule]) {
            self.rules = rules
        }

        func validate(_ item: GlobalIsolationRequest) -> [String] {
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

        func requireValid(_ item: GlobalIsolationRequest) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.label()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [GlobalIsolationRequest]) -> [String: [String]] {
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

    static func defaultGlobalIsolationRequestValidator() -> GlobalIsolationRequestValidator {
        return GlobalIsolationRequestValidator(
            rules: [
                GlobalIsolationRequestRegionLengthRule(maxLength: 16),
                GlobalIsolationRequestRateRangeRule(min: 2.7, max: 4006.5),
                GlobalIsolationRequestRequiredSourceRule(message: "global isolation request needs a value"),
                GlobalIsolationRequestRequiredCodeRule(message: "global isolation request needs a value"),
                GlobalIsolationRequestTitleLengthRule(maxLength: 255),
                GlobalIsolationRequestActiveGuardRule(limit: 4.0),
            ]
        )
    }
}
