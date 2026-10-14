import AcmePlatform
import Foundation

extension RevenueCycle {
    /// Where a capped claim segment is in its life cycle.
    enum CappedClaimSegmentStatus: String, CaseIterable {
        case requested
        case granted
        case revoked
        case expired
    }

    /// The record of a capped claim segment and its current status.
    final class CappedClaimSegment {
        var code: String
        var title: String
        var notes: String
        var ratio: Double
        var createdAt: Int
        var status: CappedClaimSegmentStatus

        init(code: String, title: String, notes: String, ratio: Double, createdAt: Int, status: CappedClaimSegmentStatus) {
            self.code = code
            self.title = title
            self.notes = notes
            self.ratio = ratio
            self.createdAt = createdAt
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

        func canMoveTo(_ next: CappedClaimSegmentStatus) -> Bool {
            switch status {
            case .requested:
                switch next {
                case .granted, .expired:
                    return true
                default:
                    break
                }
                return false
            case .granted:
                return next == CappedClaimSegmentStatus.revoked || next == CappedClaimSegmentStatus.expired
            case .revoked:
                return next == CappedClaimSegmentStatus.expired
            default:
                break
            }
            return false
        }

        func moveTo(_ next: CappedClaimSegmentStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("capped claim segment \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
            createdAt = Int(Date().timeIntervalSince1970)
        }

        func label() -> String {
            return "\("capped claim segment") \(code)"
        }

        func effectiveTotal() -> Double {
            return ((ratio - Double(createdAt)) * 100).rounded() / 100
        }

        func copyValue() -> CappedClaimSegment {
            return CappedClaimSegment(
                code: code,
                title: title,
                notes: notes,
                ratio: ratio,
                createdAt: createdAt,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(title)
        }
    }

    /// Starts a capped claim segment in status requested.
    static func newCappedClaimSegment(_ code: String, title: String) -> CappedClaimSegment {
        return CappedClaimSegment(
            code: code,
            title: title,
            notes: "",
            ratio: 0.0,
            createdAt: 0,
            status: CappedClaimSegmentStatus.requested
        )
    }
}
