import AcmePlatform
import Foundation

extension Pharmacy {
    /// Where a recall segment is in its life cycle.
    enum RecallSegmentStatus: String, CaseIterable {
        case requested
        case granted
        case revoked
        case expired
    }

    /// One recall segment, with what the planners need to act on it.
    final class RecallSegment {
        var code: String
        var name: String
        var ceiling: Double
        var refills: Int
        var label: String
        var ratio: Double
        var country: String
        var channel: String
        var status: RecallSegmentStatus

        init(code: String, name: String, ceiling: Double, refills: Int, label: String, ratio: Double, country: String, channel: String, status: RecallSegmentStatus) {
            self.code = code
            self.name = name
            self.ceiling = ceiling
            self.refills = refills
            self.label = label
            self.ratio = ratio
            self.country = country
            self.channel = channel
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

        func canMoveTo(_ next: RecallSegmentStatus) -> Bool {
            switch status {
            case .requested:
                switch next {
                case .revoked:
                    return true
                default:
                    break
                }
                return false
            case .granted:
                return next == RecallSegmentStatus.expired
            case .revoked:
                return next == RecallSegmentStatus.expired
            default:
                break
            }
            return false
        }

        func moveTo(_ next: RecallSegmentStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("recall segment \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
        }

        func displayLabel() -> String {
            return "\(code) [\(name)]"
        }

        func effectiveLoad() -> Double {
            return ((ceiling + ratio) * 100).rounded() / 100
        }

        func copyValue() -> RecallSegment {
            return RecallSegment(
                code: code,
                name: name,
                ceiling: ceiling,
                refills: refills,
                label: label,
                ratio: ratio,
                country: country,
                channel: channel,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(country)
        }
    }

    /// Starts a recall segment in status requested.
    static func newRecallSegment(_ code: String, name: String) -> RecallSegment {
        return RecallSegment(
            code: code,
            name: name,
            ceiling: 0.0,
            refills: 0,
            label: "",
            ratio: 0.0,
            country: "",
            channel: "",
            status: RecallSegmentStatus.requested
        )
    }
}
