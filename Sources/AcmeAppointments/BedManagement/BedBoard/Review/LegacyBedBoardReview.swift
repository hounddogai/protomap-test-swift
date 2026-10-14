import AcmePlatform
import Foundation

extension BedManagement {
    /// Where a legacy bed board review is in its life cycle.
    enum LegacyBedBoardReviewStatus: String, CaseIterable {
        case requested
        case granted
        case revoked
        case expired
    }

    /// A legacy bed board review. Its code is unique within a tenant.
    final class LegacyBedBoardReview {
        var code: String
        var name: String
        var active: Bool
        var pinned: Bool
        var sequence: Int
        var timezone: String
        var quantity: Int
        var segment: String
        var externalRef: String
        var margin: Double
        var diagnosisCode: String
        var status: LegacyBedBoardReviewStatus

        init(code: String, name: String, active: Bool, pinned: Bool, sequence: Int, timezone: String, quantity: Int, segment: String, externalRef: String, margin: Double, diagnosisCode: String, status: LegacyBedBoardReviewStatus) {
            self.code = code
            self.name = name
            self.active = active
            self.pinned = pinned
            self.sequence = sequence
            self.timezone = timezone
            self.quantity = quantity
            self.segment = segment
            self.externalRef = externalRef
            self.margin = margin
            self.diagnosisCode = diagnosisCode
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

        func canMoveTo(_ next: LegacyBedBoardReviewStatus) -> Bool {
            switch status {
            case .requested:
                return next == LegacyBedBoardReviewStatus.revoked || next == LegacyBedBoardReviewStatus.expired
            case .granted:
                switch next {
                case .expired:
                    return true
                default:
                    break
                }
                return false
            case .revoked:
                return next == LegacyBedBoardReviewStatus.expired
            default:
                break
            }
            return false
        }

        func moveTo(_ next: LegacyBedBoardReviewStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("legacy bed board review \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
        }

        func label() -> String {
            return "\("legacy bed board review") \(code)"
        }

        func netTotal() -> Double {
            return ((margin + Double(sequence)) * 100).rounded() / 100
        }

        func copyValue() -> LegacyBedBoardReview {
            return LegacyBedBoardReview(
                code: code,
                name: name,
                active: active,
                pinned: pinned,
                sequence: sequence,
                timezone: timezone,
                quantity: quantity,
                segment: segment,
                externalRef: externalRef,
                margin: margin,
                diagnosisCode: diagnosisCode,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(segment)
        }
    }

    /// Starts a legacy bed board review in status requested.
    static func newLegacyBedBoardReview(_ code: String, name: String) -> LegacyBedBoardReview {
        return LegacyBedBoardReview(
            code: code,
            name: name,
            active: false,
            pinned: false,
            sequence: 0,
            timezone: "",
            quantity: 0,
            segment: "",
            externalRef: "",
            margin: 0.0,
            diagnosisCode: "",
            status: LegacyBedBoardReviewStatus.requested
        )
    }
}
