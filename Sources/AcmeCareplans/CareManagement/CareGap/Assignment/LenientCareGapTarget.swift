import AcmePlatform
import Foundation

extension CareManagement {
    /// Where a lenient care gap target is in its life cycle.
    enum LenientCareGapTargetStatus: String, CaseIterable {
        case planned
        case scheduled
        case inProgress = "in_progress"
        case completed
        case cancelled
    }

    /// A lenient care gap target. Its code is unique within a tenant.
    final class LenientCareGapTarget {
        var code: String
        var label: String
        var tags: [String]
        var maximum: Double
        var checksum: String
        var weight: Double
        var clinicianID: String
        var expiresAt: Int
        var status: LenientCareGapTargetStatus

        init(code: String, label: String, tags: [String], maximum: Double, checksum: String, weight: Double, clinicianID: String, expiresAt: Int, status: LenientCareGapTargetStatus) {
            self.code = code
            self.label = label
            self.tags = tags
            self.maximum = maximum
            self.checksum = checksum
            self.weight = weight
            self.clinicianID = clinicianID
            self.expiresAt = expiresAt
            self.status = status
        }

        /// Reports whether the record can no longer change status.
        func isTerminal() -> Bool {
            switch status {
            case .cancelled:
                return true
            default:
                break
            }
            return false
        }

        func canMoveTo(_ next: LenientCareGapTargetStatus) -> Bool {
            switch status {
            case .planned:
                return next == LenientCareGapTargetStatus.inProgress || next == LenientCareGapTargetStatus.cancelled
            case .scheduled:
                return next == LenientCareGapTargetStatus.completed || next == LenientCareGapTargetStatus.cancelled
            case .inProgress:
                return next == LenientCareGapTargetStatus.completed || next == LenientCareGapTargetStatus.cancelled
            case .completed:
                return next == LenientCareGapTargetStatus.cancelled
            default:
                break
            }
            return false
        }

        func moveTo(_ next: LenientCareGapTargetStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("lenient care gap target \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
            expiresAt = Int(Date().timeIntervalSince1970)
        }

        func displayLabel() -> String {
            return "\("lenient care gap target") \(code)"
        }

        func hasTag(_ tag: String) -> Bool {
            for candidate in tags {
                if Kit.Text.normalize(candidate) == Kit.Text.normalize(tag) {
                    return true
                }
            }
            return false
        }

        func projectedValue() -> Double {
            return (Double(expiresAt) * weight * 100).rounded() / 100
        }

        func copyValue() -> LenientCareGapTarget {
            return LenientCareGapTarget(
                code: code,
                label: label,
                tags: tags,
                maximum: maximum,
                checksum: checksum,
                weight: weight,
                clinicianID: clinicianID,
                expiresAt: expiresAt,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(label)
        }
    }

    /// Starts a lenient care gap target in status planned.
    static func newLenientCareGapTarget(_ code: String, label: String) -> LenientCareGapTarget {
        return LenientCareGapTarget(
            code: code,
            label: label,
            tags: [],
            maximum: 0.0,
            checksum: "",
            weight: 0.0,
            clinicianID: "",
            expiresAt: 0,
            status: LenientCareGapTargetStatus.planned
        )
    }
}
