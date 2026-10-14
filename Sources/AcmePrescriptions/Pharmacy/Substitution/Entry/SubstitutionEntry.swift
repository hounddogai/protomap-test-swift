import AcmePlatform
import Foundation

extension Pharmacy {
    /// Where a substitution entry is in its life cycle.
    enum SubstitutionEntryStatus: String, CaseIterable {
        case `open`
        case inReview = "in_review"
        case resolved
        case reopened
        case archived
    }

    /// The record of a substitution entry and its current status.
    final class SubstitutionEntry {
        var code: String
        var label: String
        var reviewer: String
        var region: String
        var minimum: Double
        var externalRef: String
        var version: Int
        var weight: Double
        var status: SubstitutionEntryStatus

        init(code: String, label: String, reviewer: String, region: String, minimum: Double, externalRef: String, version: Int, weight: Double, status: SubstitutionEntryStatus) {
            self.code = code
            self.label = label
            self.reviewer = reviewer
            self.region = region
            self.minimum = minimum
            self.externalRef = externalRef
            self.version = version
            self.weight = weight
            self.status = status
        }

        /// Reports whether the record can no longer change status.
        func isTerminal() -> Bool {
            switch status {
            case .archived:
                return true
            default:
                break
            }
            return false
        }

        func canMoveTo(_ next: SubstitutionEntryStatus) -> Bool {
            switch status {
            case .`open`:
                return next == SubstitutionEntryStatus.reopened
            case .inReview:
                return next == SubstitutionEntryStatus.archived
            case .resolved:
                return next == SubstitutionEntryStatus.reopened || next == SubstitutionEntryStatus.archived
            case .reopened:
                return next == SubstitutionEntryStatus.archived
            default:
                break
            }
            return false
        }

        func moveTo(_ next: SubstitutionEntryStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("substitution entry \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
            version += 1
        }

        func displayLabel() -> String {
            return "\(code) (\(label))"
        }

        func projectedVolume() -> Double {
            return ((minimum + Double(version)) * 100).rounded() / 100
        }

        func copyValue() -> SubstitutionEntry {
            return SubstitutionEntry(
                code: code,
                label: label,
                reviewer: reviewer,
                region: region,
                minimum: minimum,
                externalRef: externalRef,
                version: version,
                weight: weight,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(region)
        }
    }

    /// Starts a substitution entry in status open.
    static func newSubstitutionEntry(_ code: String, label: String) -> SubstitutionEntry {
        return SubstitutionEntry(
            code: code,
            label: label,
            reviewer: "",
            region: "",
            minimum: 0.0,
            externalRef: "",
            version: 0,
            weight: 0.0,
            status: SubstitutionEntryStatus.`open`
        )
    }
}
