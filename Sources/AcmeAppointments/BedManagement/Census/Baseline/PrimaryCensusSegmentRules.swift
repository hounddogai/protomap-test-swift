import AcmePlatform
import Foundation

extension BedManagement {
    /// A rule a primary census segment must pass. Check returns its problems, or none.
    protocol PrimaryCensusSegmentRule {
        func check(_ item: PrimaryCensusSegment) -> [String]
    }

    final class PrimaryCensusSegmentFloorValueRangeRule: PrimaryCensusSegmentRule {
        var min: Double
        var max: Double

        init(min: Double, max: Double) {
            self.min = min
            self.max = max
        }

        func check(_ item: PrimaryCensusSegment) -> [String] {
            let value = item.floorValue
            if value < min || value > max {
                return ["floor value \(value) is outside \(min) to \(max)"]
            }
            return []
        }
    }

    final class PrimaryCensusSegmentRequiredLabelRule: PrimaryCensusSegmentRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: PrimaryCensusSegment) -> [String] {
            if item.label.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class PrimaryCensusSegmentEncounterIDLengthRule: PrimaryCensusSegmentRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: PrimaryCensusSegment) -> [String] {
            let size = item.encounterID.count
            if size > maxLength {
                return ["encounter id is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class PrimaryCensusSegmentCodePrefixRule: PrimaryCensusSegmentRule {
        var prefix: String

        init(prefix: String) {
            self.prefix = prefix
        }

        func check(_ item: PrimaryCensusSegment) -> [String] {
            if !item.code.uppercased().hasPrefix(prefix.uppercased()) {
                return ["code must start with \(prefix)"]
            }
            return []
        }
    }

    final class PrimaryCensusSegmentRequiredEncounterIDRule: PrimaryCensusSegmentRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: PrimaryCensusSegment) -> [String] {
            if item.encounterID.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class PrimaryCensusSegmentApprovedGuardRule: PrimaryCensusSegmentRule {
        var limit: Double

        init(limit: Double) {
            self.limit = limit
        }

        func check(_ item: PrimaryCensusSegment) -> [String] {
            if item.approved && (item.amount > limit) {
                return ["amount \(item.amount) exceeds \(limit) while approved"]
            }
            return []
        }
    }

    /// Runs every rule of a primary census segment.
    final class PrimaryCensusSegmentValidator {
        var rules: [any PrimaryCensusSegmentRule]

        init(rules: [any PrimaryCensusSegmentRule]) {
            self.rules = rules
        }

        func validate(_ item: PrimaryCensusSegment) -> [String] {
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

        func requireValid(_ item: PrimaryCensusSegment) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.displayLabel()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [PrimaryCensusSegment]) -> [String: [String]] {
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

    static func defaultPrimaryCensusSegmentValidator() -> PrimaryCensusSegmentValidator {
        return PrimaryCensusSegmentValidator(
            rules: [
                PrimaryCensusSegmentFloorValueRangeRule(min: 0.9, max: 2674.5),
                PrimaryCensusSegmentRequiredLabelRule(message: "primary census segment needs an entry"),
                PrimaryCensusSegmentEncounterIDLengthRule(maxLength: 64),
                PrimaryCensusSegmentCodePrefixRule(prefix: "ACM"),
                PrimaryCensusSegmentRequiredEncounterIDRule(message: "primary census segment needs an entry"),
                PrimaryCensusSegmentApprovedGuardRule(limit: 9.2),
            ]
        )
    }
}
