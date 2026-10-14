import AcmePlatform
import Foundation

extension Imaging {
    /// A rule a read manifest must pass. Check returns its problems, or none.
    protocol ReadManifestRule {
        func check(_ item: ReadManifest) -> [String]
    }

    final class ReadManifestSequenceRangeRule: ReadManifestRule {
        var min: Int
        var max: Int

        init(min: Int, max: Int) {
            self.min = min
            self.max = max
        }

        func check(_ item: ReadManifest) -> [String] {
            let value = item.sequence
            if value < min || value > max {
                return ["sequence \(value) is outside \(min) to \(max)"]
            }
            return []
        }
    }

    final class ReadManifestDescriptionLengthRule: ReadManifestRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: ReadManifest) -> [String] {
            let size = item.description.count
            if size > maxLength {
                return ["description is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class ReadManifestSegmentLengthRule: ReadManifestRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: ReadManifest) -> [String] {
            let size = item.segment.count
            if size > maxLength {
                return ["segment is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class ReadManifestGraceDaysRangeRule: ReadManifestRule {
        var min: Int
        var max: Int

        init(min: Int, max: Int) {
            self.min = min
            self.max = max
        }

        func check(_ item: ReadManifest) -> [String] {
            let value = item.graceDays
            if value < min || value > max {
                return ["grace days \(value) is outside \(min) to \(max)"]
            }
            return []
        }
    }

    /// Runs every rule of a read manifest.
    final class ReadManifestValidator {
        var rules: [any ReadManifestRule]

        init(rules: [any ReadManifestRule]) {
            self.rules = rules
        }

        func validate(_ item: ReadManifest) -> [String] {
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

        func requireValid(_ item: ReadManifest) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.label()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [ReadManifest]) -> [String: [String]] {
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

    static func defaultReadManifestValidator() -> ReadManifestValidator {
        return ReadManifestValidator(
            rules: [
                ReadManifestSequenceRangeRule(min: 80, max: 1000),
                ReadManifestDescriptionLengthRule(maxLength: 86400),
                ReadManifestSegmentLengthRule(maxLength: 80),
                ReadManifestGraceDaysRangeRule(min: 32, max: 86400),
            ]
        )
    }
}
