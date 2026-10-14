import AcmePlatform
import Foundation

extension Referrals {
    /// Where a fallback network entry is in its life cycle.
    enum FallbackNetworkEntryStatus: String, CaseIterable {
        case created
        case validated
        case published
        case retired
    }

    /// A fallback network entry. Its code is unique within a tenant.
    final class FallbackNetworkEntry {
        var code: String
        var label: String
        var pinned: Bool
        var capacity: Int
        var ownerID: String
        var maximum: Double
        var status: FallbackNetworkEntryStatus

        init(code: String, label: String, pinned: Bool, capacity: Int, ownerID: String, maximum: Double, status: FallbackNetworkEntryStatus) {
            self.code = code
            self.label = label
            self.pinned = pinned
            self.capacity = capacity
            self.ownerID = ownerID
            self.maximum = maximum
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

        func canMoveTo(_ next: FallbackNetworkEntryStatus) -> Bool {
            switch status {
            case .created:
                switch next {
                case .published, .retired:
                    return true
                default:
                    break
                }
                return false
            case .validated:
                switch next {
                case .published, .retired:
                    return true
                default:
                    break
                }
                return false
            case .published:
                switch next {
                case .retired:
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

        func moveTo(_ next: FallbackNetworkEntryStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("fallback network entry \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
        }

        func displayLabel() -> String {
            return "\(code) [\(label)]"
        }

        func projectedLoad() -> Double {
            return ((maximum + Double(capacity)) * 100).rounded() / 100
        }

        func copyValue() -> FallbackNetworkEntry {
            return FallbackNetworkEntry(
                code: code,
                label: label,
                pinned: pinned,
                capacity: capacity,
                ownerID: ownerID,
                maximum: maximum,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(label)
        }
    }

    /// Starts a fallback network entry in status created.
    static func newFallbackNetworkEntry(_ code: String, label: String) -> FallbackNetworkEntry {
        return FallbackNetworkEntry(
            code: code,
            label: label,
            pinned: false,
            capacity: 0,
            ownerID: "",
            maximum: 0.0,
            status: FallbackNetworkEntryStatus.created
        )
    }
}
