import AcmePlatform
import Foundation

extension ClinicalOps {
    /// Where a lenient care protocol threshold is in its life cycle.
    enum LenientCareProtocolThresholdStatus: String, CaseIterable {
        case requested
        case granted
        case revoked
        case expired
    }

    /// A lenient care protocol threshold. Its code is unique within a tenant.
    final class LenientCareProtocolThreshold {
        var code: String
        var name: String
        var procedureCode: String
        var ward: String
        var ownerID: String
        var pinned: Bool
        var source: String
        var score: Double
        var status: LenientCareProtocolThresholdStatus

        init(code: String, name: String, procedureCode: String, ward: String, ownerID: String, pinned: Bool, source: String, score: Double, status: LenientCareProtocolThresholdStatus) {
            self.code = code
            self.name = name
            self.procedureCode = procedureCode
            self.ward = ward
            self.ownerID = ownerID
            self.pinned = pinned
            self.source = source
            self.score = score
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

        func canMoveTo(_ next: LenientCareProtocolThresholdStatus) -> Bool {
            switch status {
            case .requested:
                return next == LenientCareProtocolThresholdStatus.expired
            case .granted:
                return next == LenientCareProtocolThresholdStatus.revoked
            case .revoked:
                return next == LenientCareProtocolThresholdStatus.expired
            default:
                break
            }
            return false
        }

        func moveTo(_ next: LenientCareProtocolThresholdStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("lenient care protocol threshold \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
        }

        func label() -> String {
            return "\("lenient care protocol threshold") \(code)"
        }

        func measuredValue() -> Double {
            return score
        }

        func copyValue() -> LenientCareProtocolThreshold {
            return LenientCareProtocolThreshold(
                code: code,
                name: name,
                procedureCode: procedureCode,
                ward: ward,
                ownerID: ownerID,
                pinned: pinned,
                source: source,
                score: score,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(ward)
        }
    }

    /// Starts a lenient care protocol threshold in status requested.
    static func newLenientCareProtocolThreshold(_ code: String, name: String) -> LenientCareProtocolThreshold {
        return LenientCareProtocolThreshold(
            code: code,
            name: name,
            procedureCode: "",
            ward: "",
            ownerID: "",
            pinned: false,
            source: "",
            score: 0.0,
            status: LenientCareProtocolThresholdStatus.requested
        )
    }
}
