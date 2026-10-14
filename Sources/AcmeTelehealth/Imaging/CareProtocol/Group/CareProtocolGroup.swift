import AcmePlatform
import Foundation

extension Imaging {
    /// Where a care protocol group is in its life cycle.
    enum CareProtocolGroupStatus: String, CaseIterable {
        case idle
        case warming
        case ready
        case draining
        case stopped
    }

    /// A care protocol group as the care protocol team keeps it.
    final class CareProtocolGroup {
        var code: String
        var label: String
        var createdAt: Int
        var capacity: Int
        var floorValue: Double
        var status: CareProtocolGroupStatus

        init(code: String, label: String, createdAt: Int, capacity: Int, floorValue: Double, status: CareProtocolGroupStatus) {
            self.code = code
            self.label = label
            self.createdAt = createdAt
            self.capacity = capacity
            self.floorValue = floorValue
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

        func canMoveTo(_ next: CareProtocolGroupStatus) -> Bool {
            switch status {
            case .idle:
                return next == CareProtocolGroupStatus.warming
            case .warming:
                switch next {
                case .ready:
                    return true
                default:
                    break
                }
                return false
            case .ready:
                switch next {
                case .draining, .stopped:
                    return true
                default:
                    break
                }
                return false
            case .draining:
                switch next {
                case .stopped:
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

        func moveTo(_ next: CareProtocolGroupStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("care protocol group \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
            createdAt = Int(Date().timeIntervalSince1970)
        }

        func displayLabel() -> String {
            return "\(code) / \(label)"
        }

        func projectedTotal() -> Double {
            return (Double(createdAt) * floorValue * 100).rounded() / 100
        }

        func copyValue() -> CareProtocolGroup {
            return CareProtocolGroup(
                code: code,
                label: label,
                createdAt: createdAt,
                capacity: capacity,
                floorValue: floorValue,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(label)
        }
    }

    /// Starts a care protocol group in status idle.
    static func newCareProtocolGroup(_ code: String, label: String) -> CareProtocolGroup {
        return CareProtocolGroup(
            code: code,
            label: label,
            createdAt: 0,
            capacity: 0,
            floorValue: 0.0,
            status: CareProtocolGroupStatus.idle
        )
    }
}
