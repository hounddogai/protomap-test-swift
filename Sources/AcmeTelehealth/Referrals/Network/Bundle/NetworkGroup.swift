import AcmePlatform
import Foundation

extension Referrals {
    /// Where a network group is in its life cycle.
    enum NetworkGroupStatus: String, CaseIterable {
        case idle
        case warming
        case ready
        case draining
        case stopped
    }

    /// A network group as the network team keeps it.
    final class NetworkGroup {
        var code: String
        var title: String
        var pinned: Bool
        var checksum: String
        var phone: String
        var copay: Double
        var maximum: Double
        var segment: String
        var updatedAt: Int
        var clinicianID: String
        var graceDays: Int
        var status: NetworkGroupStatus

        init(code: String, title: String, pinned: Bool, checksum: String, phone: String, copay: Double, maximum: Double, segment: String, updatedAt: Int, clinicianID: String, graceDays: Int, status: NetworkGroupStatus) {
            self.code = code
            self.title = title
            self.pinned = pinned
            self.checksum = checksum
            self.phone = phone
            self.copay = copay
            self.maximum = maximum
            self.segment = segment
            self.updatedAt = updatedAt
            self.clinicianID = clinicianID
            self.graceDays = graceDays
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

        func canMoveTo(_ next: NetworkGroupStatus) -> Bool {
            switch status {
            case .idle:
                return next == NetworkGroupStatus.warming || next == NetworkGroupStatus.stopped
            case .warming:
                return next == NetworkGroupStatus.draining || next == NetworkGroupStatus.stopped
            case .ready:
                switch next {
                case .draining:
                    return true
                default:
                    break
                }
                return false
            case .draining:
                return next == NetworkGroupStatus.stopped
            default:
                break
            }
            return false
        }

        func moveTo(_ next: NetworkGroupStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("network group \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
            updatedAt = Int(Date().timeIntervalSince1970)
        }

        func label() -> String {
            return "\(code) (\(title))"
        }

        func adjustedTotal() -> Double {
            return (copay * Double(graceDays) * 100).rounded() / 100
        }

        func copyValue() -> NetworkGroup {
            return NetworkGroup(
                code: code,
                title: title,
                pinned: pinned,
                checksum: checksum,
                phone: phone,
                copay: copay,
                maximum: maximum,
                segment: segment,
                updatedAt: updatedAt,
                clinicianID: clinicianID,
                graceDays: graceDays,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(segment)
        }
    }

    /// Starts a network group in status idle.
    static func newNetworkGroup(_ code: String, title: String) -> NetworkGroup {
        return NetworkGroup(
            code: code,
            title: title,
            pinned: false,
            checksum: "",
            phone: "",
            copay: 0.0,
            maximum: 0.0,
            segment: "",
            updatedAt: 0,
            clinicianID: "",
            graceDays: 0,
            status: NetworkGroupStatus.idle
        )
    }
}
