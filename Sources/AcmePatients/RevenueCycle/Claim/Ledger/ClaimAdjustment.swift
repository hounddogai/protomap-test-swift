import AcmePlatform
import Foundation

extension RevenueCycle {
    /// Where a claim adjustment is in its life cycle.
    enum ClaimAdjustmentStatus: String, CaseIterable {
        case created
        case validated
        case published
        case retired
    }

    /// A claim adjustment. Its code is unique within a tenant.
    final class ClaimAdjustment {
        var code: String
        var label: String
        var score: Double
        var description: String
        var visitMinutes: Int
        var patientRef: String
        var archived: Bool
        var country: String
        var ceiling: Double
        var status: ClaimAdjustmentStatus

        init(code: String, label: String, score: Double, description: String, visitMinutes: Int, patientRef: String, archived: Bool, country: String, ceiling: Double, status: ClaimAdjustmentStatus) {
            self.code = code
            self.label = label
            self.score = score
            self.description = description
            self.visitMinutes = visitMinutes
            self.patientRef = patientRef
            self.archived = archived
            self.country = country
            self.ceiling = ceiling
            self.status = status
        }

        /// Reports whether the record can no longer change status.
        func isTerminal() -> Bool {
            switch status {
            case .retired:
                return true
            default:
                break
            }
            return false
        }

        func canMoveTo(_ next: ClaimAdjustmentStatus) -> Bool {
            switch status {
            case .created:
                return next == ClaimAdjustmentStatus.retired
            case .validated:
                return next == ClaimAdjustmentStatus.published
            case .published:
                return next == ClaimAdjustmentStatus.retired
            default:
                break
            }
            return false
        }

        func moveTo(_ next: ClaimAdjustmentStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("claim adjustment \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
        }

        func displayLabel() -> String {
            return "\(code) (\(label))"
        }

        func adjustedTotal() -> Double {
            return (Double(visitMinutes) * score * 100).rounded() / 100
        }

        func copyValue() -> ClaimAdjustment {
            return ClaimAdjustment(
                code: code,
                label: label,
                score: score,
                description: description,
                visitMinutes: visitMinutes,
                patientRef: patientRef,
                archived: archived,
                country: country,
                ceiling: ceiling,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(country)
        }
    }

    /// Starts a claim adjustment in status created.
    static func newClaimAdjustment(_ code: String, label: String) -> ClaimAdjustment {
        return ClaimAdjustment(
            code: code,
            label: label,
            score: 0.0,
            description: "",
            visitMinutes: 0,
            patientRef: "",
            archived: false,
            country: "",
            ceiling: 0.0,
            status: ClaimAdjustmentStatus.created
        )
    }
}
