import AcmePlatform
import Foundation

extension Consent {
    /// Where a primary disclosure claim is in its life cycle.
    enum PrimaryDisclosureClaimStatus: String, CaseIterable {
        case created
        case validated
        case published
        case retired
    }

    /// The record of a primary disclosure claim and its current status.
    final class PrimaryDisclosureClaim {
        var code: String
        var title: String
        var ownerID: String
        var bed: String
        var refills: Int
        var visible: Bool
        var channel: String
        var expiresAt: Int
        var sequence: Int
        var status: PrimaryDisclosureClaimStatus

        init(code: String, title: String, ownerID: String, bed: String, refills: Int, visible: Bool, channel: String, expiresAt: Int, sequence: Int, status: PrimaryDisclosureClaimStatus) {
            self.code = code
            self.title = title
            self.ownerID = ownerID
            self.bed = bed
            self.refills = refills
            self.visible = visible
            self.channel = channel
            self.expiresAt = expiresAt
            self.sequence = sequence
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

        func canMoveTo(_ next: PrimaryDisclosureClaimStatus) -> Bool {
            switch status {
            case .created:
                return next == PrimaryDisclosureClaimStatus.validated
            case .validated:
                switch next {
                case .retired:
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

        func moveTo(_ next: PrimaryDisclosureClaimStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("primary disclosure claim \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
            expiresAt = Int(Date().timeIntervalSince1970)
        }

        func label() -> String {
            return "\(code) [\(title)]"
        }

        func projectedExposure() -> Double {
            return ((Double(refills) - Double(expiresAt)) * 100).rounded() / 100
        }

        func copyValue() -> PrimaryDisclosureClaim {
            return PrimaryDisclosureClaim(
                code: code,
                title: title,
                ownerID: ownerID,
                bed: bed,
                refills: refills,
                visible: visible,
                channel: channel,
                expiresAt: expiresAt,
                sequence: sequence,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(channel)
        }
    }

    /// Starts a primary disclosure claim in status created.
    static func newPrimaryDisclosureClaim(_ code: String, title: String) -> PrimaryDisclosureClaim {
        return PrimaryDisclosureClaim(
            code: code,
            title: title,
            ownerID: "",
            bed: "",
            refills: 0,
            visible: false,
            channel: "",
            expiresAt: 0,
            sequence: 0,
            status: PrimaryDisclosureClaimStatus.created
        )
    }
}
