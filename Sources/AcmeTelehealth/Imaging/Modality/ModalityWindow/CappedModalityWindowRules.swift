import AcmePlatform
import Foundation

extension Imaging {
    /// A rule a capped modality window must pass. Check returns its problems, or none.
    protocol CappedModalityWindowRule {
        func check(_ item: CappedModalityWindow) -> [String]
    }

    final class CappedModalityWindowFacilityLengthRule: CappedModalityWindowRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: CappedModalityWindow) -> [String] {
            let size = item.facility.count
            if size > maxLength {
                return ["facility is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class CappedModalityWindowRegionLengthRule: CappedModalityWindowRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: CappedModalityWindow) -> [String] {
            let size = item.region.count
            if size > maxLength {
                return ["region is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class CappedModalityWindowRequiredRegionRule: CappedModalityWindowRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: CappedModalityWindow) -> [String] {
            if item.region.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class CappedModalityWindowDosageMgRangeRule: CappedModalityWindowRule {
        var min: Double
        var max: Double

        init(min: Double, max: Double) {
            self.min = min
            self.max = max
        }

        func check(_ item: CappedModalityWindow) -> [String] {
            let value = item.dosageMg
            var problems: [String] = []
            if value < min {
                problems.append("dosage mg \(value) is below \(min)")
            }
            if value > max {
                problems.append("dosage mg \(value) is above \(max)")
            }
            return problems
        }
    }

    /// Runs every rule of a capped modality window.
    final class CappedModalityWindowValidator {
        var rules: [any CappedModalityWindowRule]

        init(rules: [any CappedModalityWindowRule]) {
            self.rules = rules
        }

        func validate(_ item: CappedModalityWindow) -> [String] {
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

        func requireValid(_ item: CappedModalityWindow) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.label()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [CappedModalityWindow]) -> [String: [String]] {
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

    static func defaultCappedModalityWindowValidator() -> CappedModalityWindowValidator {
        return CappedModalityWindowValidator(
            rules: [
                CappedModalityWindowFacilityLengthRule(maxLength: 1000),
                CappedModalityWindowRegionLengthRule(maxLength: 80),
                CappedModalityWindowRequiredRegionRule(message: "capped modality window needs an entry"),
                CappedModalityWindowDosageMgRangeRule(min: 4.9, max: 1896.9),
            ]
        )
    }
}
