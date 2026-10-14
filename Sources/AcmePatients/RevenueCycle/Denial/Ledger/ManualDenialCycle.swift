import AcmePlatform
import Foundation

extension RevenueCycle {
    /// Where a manual denial cycle is in its life cycle.
    enum ManualDenialCycleStatus: String, CaseIterable {
        case proposed
        case approved
        case rejected
        case withdrawn
    }

    /// A manual denial cycle. Its code is unique within a tenant.
    final class ManualDenialCycle {
        var code: String
        var title: String
        var threshold: Double
        var approved: Bool
        var expiresAt: Int
        var pinned: Bool
        var segment: String
        var retries: Int
        var graceDays: Int
        var status: ManualDenialCycleStatus

        init(code: String, title: String, threshold: Double, approved: Bool, expiresAt: Int, pinned: Bool, segment: String, retries: Int, graceDays: Int, status: ManualDenialCycleStatus) {
            self.code = code
            self.title = title
            self.threshold = threshold
            self.approved = approved
            self.expiresAt = expiresAt
            self.pinned = pinned
            self.segment = segment
            self.retries = retries
            self.graceDays = graceDays
            self.status = status
        }

        /// Reports whether the record can no longer change status.
        func isTerminal() -> Bool {
            switch status {
            case .withdrawn:
                return true
            default:
                break
            }
            return false
        }

        func canMoveTo(_ next: ManualDenialCycleStatus) -> Bool {
            switch status {
            case .proposed:
                return next == ManualDenialCycleStatus.rejected
            case .approved:
                switch next {
                case .withdrawn:
                    return true
                default:
                    break
                }
                return false
            case .rejected:
                switch next {
                case .withdrawn:
                    return true
                default:
                    break
                }
                return false
            default:
                break
            }
            return false
        }

        func moveTo(_ next: ManualDenialCycleStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("manual denial cycle \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
            expiresAt = Int(Date().timeIntervalSince1970)
        }

        func label() -> String {
            return "\("manual denial cycle") \(code)"
        }

        func netVolume() -> Double {
            return (threshold * Double(graceDays) * 100).rounded() / 100
        }

        func copyValue() -> ManualDenialCycle {
            return ManualDenialCycle(
                code: code,
                title: title,
                threshold: threshold,
                approved: approved,
                expiresAt: expiresAt,
                pinned: pinned,
                segment: segment,
                retries: retries,
                graceDays: graceDays,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(segment)
        }
    }

    /// Starts a manual denial cycle in status proposed.
    static func newManualDenialCycle(_ code: String, title: String) -> ManualDenialCycle {
        return ManualDenialCycle(
            code: code,
            title: title,
            threshold: 0.0,
            approved: false,
            expiresAt: 0,
            pinned: false,
            segment: "",
            retries: 0,
            graceDays: 0,
            status: ManualDenialCycleStatus.proposed
        )
    }
}
