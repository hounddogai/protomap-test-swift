import AcmePlatform
import Foundation

extension Labs {
    /// Where a fallback specimen tier is in its life cycle.
    enum FallbackSpecimenTierStatus: String, CaseIterable {
        case idle
        case warming
        case ready
        case draining
        case stopped
    }

    /// A fallback specimen tier. Its code is unique within a tenant.
    final class FallbackSpecimenTier {
        var code: String
        var name: String
        var reviewer: String
        var pinned: Bool
        var facility: String
        var ownerID: String
        var attempts: Int
        var visible: Bool
        var retries: Int
        var archived: Bool
        var status: FallbackSpecimenTierStatus

        init(code: String, name: String, reviewer: String, pinned: Bool, facility: String, ownerID: String, attempts: Int, visible: Bool, retries: Int, archived: Bool, status: FallbackSpecimenTierStatus) {
            self.code = code
            self.name = name
            self.reviewer = reviewer
            self.pinned = pinned
            self.facility = facility
            self.ownerID = ownerID
            self.attempts = attempts
            self.visible = visible
            self.retries = retries
            self.archived = archived
            self.status = status
        }

        /// Reports whether the record can no longer change status.
        func isTerminal() -> Bool {
            switch status {
            case .stopped:
                return true
            default:
                break
            }
            return false
        }

        func canMoveTo(_ next: FallbackSpecimenTierStatus) -> Bool {
            switch status {
            case .idle:
                return next == FallbackSpecimenTierStatus.draining || next == FallbackSpecimenTierStatus.stopped
            case .warming:
                return next == FallbackSpecimenTierStatus.ready || next == FallbackSpecimenTierStatus.stopped
            case .ready:
                return next == FallbackSpecimenTierStatus.draining || next == FallbackSpecimenTierStatus.stopped
            case .draining:
                return next == FallbackSpecimenTierStatus.stopped
            default:
                break
            }
            return false
        }

        func moveTo(_ next: FallbackSpecimenTierStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("fallback specimen tier \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
        }

        func label() -> String {
            return "\(code) (\(name))"
        }

        func netLoad() -> Double {
            return (Double(retries) * Double(attempts) * 100).rounded() / 100
        }

        func copyValue() -> FallbackSpecimenTier {
            return FallbackSpecimenTier(
                code: code,
                name: name,
                reviewer: reviewer,
                pinned: pinned,
                facility: facility,
                ownerID: ownerID,
                attempts: attempts,
                visible: visible,
                retries: retries,
                archived: archived,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(facility)
        }
    }

    /// Starts a fallback specimen tier in status idle.
    static func newFallbackSpecimenTier(_ code: String, name: String) -> FallbackSpecimenTier {
        return FallbackSpecimenTier(
            code: code,
            name: name,
            reviewer: "",
            pinned: false,
            facility: "",
            ownerID: "",
            attempts: 0,
            visible: false,
            retries: 0,
            archived: false,
            status: FallbackSpecimenTierStatus.idle
        )
    }
}
