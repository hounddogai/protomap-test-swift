import AcmePlatform
import Foundation

extension CareManagement {
    /// Where a care gap preference is in its life cycle.
    enum CareGapPreferenceStatus: String, CaseIterable {
        case requested
        case granted
        case revoked
        case expired
    }

    /// One care gap preference, with what the planners need to act on it.
    final class CareGapPreference {
        var code: String
        var name: String
        var limit: Int
        var score: Double
        var floorValue: Double
        var quantity: Int
        var margin: Double
        var status: CareGapPreferenceStatus

        init(code: String, name: String, limit: Int, score: Double, floorValue: Double, quantity: Int, margin: Double, status: CareGapPreferenceStatus) {
            self.code = code
            self.name = name
            self.limit = limit
            self.score = score
            self.floorValue = floorValue
            self.quantity = quantity
            self.margin = margin
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

        func canMoveTo(_ next: CareGapPreferenceStatus) -> Bool {
            switch status {
            case .requested:
                return next == CareGapPreferenceStatus.revoked
            case .granted:
                return next == CareGapPreferenceStatus.revoked || next == CareGapPreferenceStatus.expired
            case .revoked:
                return next == CareGapPreferenceStatus.expired
            default:
                break
            }
            return false
        }

        func moveTo(_ next: CareGapPreferenceStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("care gap preference \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
        }

        func label() -> String {
            return "\(code): \(name)"
        }

        func adjustedValue() -> Double {
            return (score * margin * 100).rounded() / 100
        }

        func copyValue() -> CareGapPreference {
            return CareGapPreference(
                code: code,
                name: name,
                limit: limit,
                score: score,
                floorValue: floorValue,
                quantity: quantity,
                margin: margin,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(name)
        }
    }

    /// Starts a care gap preference in status requested.
    static func newCareGapPreference(_ code: String, name: String) -> CareGapPreference {
        return CareGapPreference(
            code: code,
            name: name,
            limit: 0,
            score: 0.0,
            floorValue: 0.0,
            quantity: 0,
            margin: 0.0,
            status: CareGapPreferenceStatus.requested
        )
    }
}
