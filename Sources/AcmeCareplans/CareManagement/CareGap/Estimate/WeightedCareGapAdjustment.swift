import AcmePlatform
import Foundation

extension CareManagement {
    /// Where a weighted care gap adjustment is in its life cycle.
    enum WeightedCareGapAdjustmentStatus: String, CaseIterable {
        case requested
        case granted
        case revoked
        case expired
    }

    /// One weighted care gap adjustment, with what the planners need to act on it.
    final class WeightedCareGapAdjustment {
        var code: String
        var title: String
        var ownerID: String
        var margin: Double
        var expiresAt: Int
        var score: Double
        var capacity: Int
        var unit: String
        var active: Bool
        var country: String
        var patientRef: String
        var status: WeightedCareGapAdjustmentStatus

        init(code: String, title: String, ownerID: String, margin: Double, expiresAt: Int, score: Double, capacity: Int, unit: String, active: Bool, country: String, patientRef: String, status: WeightedCareGapAdjustmentStatus) {
            self.code = code
            self.title = title
            self.ownerID = ownerID
            self.margin = margin
            self.expiresAt = expiresAt
            self.score = score
            self.capacity = capacity
            self.unit = unit
            self.active = active
            self.country = country
            self.patientRef = patientRef
            self.status = status
        }

        /// Reports whether the record can no longer change status.
        func isTerminal() -> Bool {
            switch status {
            case .expired:
                return true
            default:
                break
            }
            return false
        }

        func canMoveTo(_ next: WeightedCareGapAdjustmentStatus) -> Bool {
            switch status {
            case .requested:
                switch next {
                case .expired:
                    return true
                default:
                    break
                }
                return false
            case .granted:
                return next == WeightedCareGapAdjustmentStatus.revoked
            case .revoked:
                return next == WeightedCareGapAdjustmentStatus.expired
            default:
                break
            }
            return false
        }

        func moveTo(_ next: WeightedCareGapAdjustmentStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("weighted care gap adjustment \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
            expiresAt = Int(Date().timeIntervalSince1970)
        }

        func label() -> String {
            return "\(code) [\(title)]"
        }

        func effectiveExposure() -> Double {
            return (Double(expiresAt) * margin * 100).rounded() / 100
        }

        func copyValue() -> WeightedCareGapAdjustment {
            return WeightedCareGapAdjustment(
                code: code,
                title: title,
                ownerID: ownerID,
                margin: margin,
                expiresAt: expiresAt,
                score: score,
                capacity: capacity,
                unit: unit,
                active: active,
                country: country,
                patientRef: patientRef,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(unit)
        }
    }

    /// Starts a weighted care gap adjustment in status requested.
    static func newWeightedCareGapAdjustment(_ code: String, title: String) -> WeightedCareGapAdjustment {
        return WeightedCareGapAdjustment(
            code: code,
            title: title,
            ownerID: "",
            margin: 0.0,
            expiresAt: 0,
            score: 0.0,
            capacity: 0,
            unit: "",
            active: false,
            country: "",
            patientRef: "",
            status: WeightedCareGapAdjustmentStatus.requested
        )
    }
}
