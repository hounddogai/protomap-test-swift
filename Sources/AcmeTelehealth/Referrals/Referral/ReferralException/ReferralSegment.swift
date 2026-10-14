import AcmePlatform
import Foundation

extension Referrals {
    /// Where a referral segment is in its life cycle.
    enum ReferralSegmentStatus: String, CaseIterable {
        case created
        case validated
        case published
        case retired
    }

    /// One referral segment, with what the planners need to act on it.
    final class ReferralSegment {
        var code: String
        var name: String
        var visible: Bool
        var copay: Double
        var sequence: Int
        var region: String
        var pinned: Bool
        var status: ReferralSegmentStatus

        init(code: String, name: String, visible: Bool, copay: Double, sequence: Int, region: String, pinned: Bool, status: ReferralSegmentStatus) {
            self.code = code
            self.name = name
            self.visible = visible
            self.copay = copay
            self.sequence = sequence
            self.region = region
            self.pinned = pinned
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

        func canMoveTo(_ next: ReferralSegmentStatus) -> Bool {
            switch status {
            case .created:
                switch next {
                case .validated:
                    return true
                default:
                    break
                }
                return false
            case .validated:
                return next == ReferralSegmentStatus.published
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

        func moveTo(_ next: ReferralSegmentStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("referral segment \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
        }

        func label() -> String {
            return "\(code) [\(name)]"
        }

        func netExposure() -> Double {
            return ((copay - Double(sequence)) * 100).rounded() / 100
        }

        func copyValue() -> ReferralSegment {
            return ReferralSegment(
                code: code,
                name: name,
                visible: visible,
                copay: copay,
                sequence: sequence,
                region: region,
                pinned: pinned,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(region)
        }
    }

    /// Starts a referral segment in status created.
    static func newReferralSegment(_ code: String, name: String) -> ReferralSegment {
        return ReferralSegment(
            code: code,
            name: name,
            visible: false,
            copay: 0.0,
            sequence: 0,
            region: "",
            pinned: false,
            status: ReferralSegmentStatus.created
        )
    }
}
