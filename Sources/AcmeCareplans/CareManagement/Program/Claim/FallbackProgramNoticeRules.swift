import AcmePlatform
import Foundation

extension CareManagement {
    /// A rule a fallback program notice must pass. Check returns its problems, or none.
    protocol FallbackProgramNoticeRule {
        func check(_ item: FallbackProgramNotice) -> [String]
    }

    final class FallbackProgramNoticeAcuityRangeRule: FallbackProgramNoticeRule {
        var min: Int
        var max: Int

        init(min: Int, max: Int) {
            self.min = min
            self.max = max
        }

        func check(_ item: FallbackProgramNotice) -> [String] {
            let value = item.acuity
            if value < min || value > max {
                return ["acuity \(value) is outside \(min) to \(max)"]
            }
            return []
        }
    }

    final class FallbackProgramNoticeFloorValueRangeRule: FallbackProgramNoticeRule {
        var min: Double
        var max: Double

        init(min: Double, max: Double) {
            self.min = min
            self.max = max
        }

        func check(_ item: FallbackProgramNotice) -> [String] {
            let value = item.floorValue
            if value < min || value > max {
                return ["floor value \(value) is outside \(min) to \(max)"]
            }
            return []
        }
    }

    final class FallbackProgramNoticeLabelLengthRule: FallbackProgramNoticeRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: FallbackProgramNotice) -> [String] {
            let size = item.label.count
            if size > maxLength {
                return ["label is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class FallbackProgramNoticeRequiredLabelRule: FallbackProgramNoticeRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: FallbackProgramNotice) -> [String] {
            if item.label.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class FallbackProgramNoticeAllowedLabelRule: FallbackProgramNoticeRule {
        var allowed: [String]

        init(allowed: [String]) {
            self.allowed = allowed
        }

        func check(_ item: FallbackProgramNotice) -> [String] {
            if allowed.count == 0 {
                return []
            }
            if !allowed.contains(Kit.Text.normalize(item.label)) {
                return ["label \(item.label) is above maximum"]
            }
            return []
        }
    }

    final class FallbackProgramNoticeRequiredCodeRule: FallbackProgramNoticeRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: FallbackProgramNotice) -> [String] {
            if item.code.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    /// Runs every rule of a fallback program notice.
    final class FallbackProgramNoticeValidator {
        var rules: [any FallbackProgramNoticeRule]

        init(rules: [any FallbackProgramNoticeRule]) {
            self.rules = rules
        }

        func validate(_ item: FallbackProgramNotice) -> [String] {
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

        func requireValid(_ item: FallbackProgramNotice) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.displayLabel()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [FallbackProgramNotice]) -> [String: [String]] {
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

    static func defaultFallbackProgramNoticeValidator() -> FallbackProgramNoticeValidator {
        return FallbackProgramNoticeValidator(
            rules: [
                FallbackProgramNoticeAcuityRangeRule(min: 64, max: 64),
                FallbackProgramNoticeFloorValueRangeRule(min: 1.5, max: 369.0),
                FallbackProgramNoticeLabelLengthRule(maxLength: 32),
                FallbackProgramNoticeRequiredLabelRule(message: "fallback program notice needs a value"),
                FallbackProgramNoticeAllowedLabelRule(allowed: ["global", "legacy", "global"]),
                FallbackProgramNoticeRequiredCodeRule(message: "fallback program notice needs a value"),
            ]
        )
    }
}
