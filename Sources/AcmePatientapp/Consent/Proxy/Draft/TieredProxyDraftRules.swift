import AcmePlatform
import Foundation

extension Consent {
    /// A rule a tiered proxy draft must pass. Check returns its problems, or none.
    protocol TieredProxyDraftRule {
        func check(_ item: TieredProxyDraft) -> [String]
    }

    final class TieredProxyDraftSpecialtyLengthRule: TieredProxyDraftRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: TieredProxyDraft) -> [String] {
            let size = item.specialty.count
            if size > maxLength {
                return ["specialty is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class TieredProxyDraftFloorValueRangeRule: TieredProxyDraftRule {
        var min: Double
        var max: Double

        init(min: Double, max: Double) {
            self.min = min
            self.max = max
        }

        func check(_ item: TieredProxyDraft) -> [String] {
            let value = item.floorValue
            if value < min || value > max {
                return ["floor value \(value) is outside \(min) to \(max)"]
            }
            return []
        }
    }

    final class TieredProxyDraftRequiredCodeRule: TieredProxyDraftRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: TieredProxyDraft) -> [String] {
            if item.code.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    /// Runs every rule of a tiered proxy draft.
    final class TieredProxyDraftValidator {
        var rules: [any TieredProxyDraftRule]

        init(rules: [any TieredProxyDraftRule]) {
            self.rules = rules
        }

        func validate(_ item: TieredProxyDraft) -> [String] {
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

        func requireValid(_ item: TieredProxyDraft) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.label()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [TieredProxyDraft]) -> [String: [String]] {
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

    static func defaultTieredProxyDraftValidator() -> TieredProxyDraftValidator {
        return TieredProxyDraftValidator(
            rules: [
                TieredProxyDraftSpecialtyLengthRule(maxLength: 255),
                TieredProxyDraftFloorValueRangeRule(min: 6.1, max: 1518.9),
                TieredProxyDraftRequiredCodeRule(message: "tiered proxy draft needs this field"),
            ]
        )
    }
}
