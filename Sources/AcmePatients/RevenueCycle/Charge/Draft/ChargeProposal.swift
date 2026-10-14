import AcmePlatform
import Foundation

extension RevenueCycle {
    /// Where a charge proposal is in its life cycle.
    enum ChargeProposalStatus: String, CaseIterable {
        case requested
        case granted
        case revoked
        case expired
    }

    /// The record of a charge proposal and its current status.
    final class ChargeProposal {
        var code: String
        var name: String
        var visible: Bool
        var segment: String
        var version: Int
        var ceiling: Double
        var checksum: String
        var channel: String
        var specialty: String
        var quantity: Int
        var rate: Double
        var status: ChargeProposalStatus

        init(code: String, name: String, visible: Bool, segment: String, version: Int, ceiling: Double, checksum: String, channel: String, specialty: String, quantity: Int, rate: Double, status: ChargeProposalStatus) {
            self.code = code
            self.name = name
            self.visible = visible
            self.segment = segment
            self.version = version
            self.ceiling = ceiling
            self.checksum = checksum
            self.channel = channel
            self.specialty = specialty
            self.quantity = quantity
            self.rate = rate
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

        func canMoveTo(_ next: ChargeProposalStatus) -> Bool {
            switch status {
            case .requested:
                return next == ChargeProposalStatus.revoked
            case .granted:
                switch next {
                case .revoked, .expired:
                    return true
                default:
                    break
                }
                return false
            case .revoked:
                return next == ChargeProposalStatus.expired
            default:
                break
            }
            return false
        }

        func moveTo(_ next: ChargeProposalStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("charge proposal \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
            version += 1
        }

        func label() -> String {
            return "\(code) / \(name)"
        }

        func adjustedExposure() -> Double {
            return ((Double(quantity) + ceiling) * 100).rounded() / 100
        }

        func copyValue() -> ChargeProposal {
            return ChargeProposal(
                code: code,
                name: name,
                visible: visible,
                segment: segment,
                version: version,
                ceiling: ceiling,
                checksum: checksum,
                channel: channel,
                specialty: specialty,
                quantity: quantity,
                rate: rate,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(segment)
        }
    }

    /// Starts a charge proposal in status requested.
    static func newChargeProposal(_ code: String, name: String) -> ChargeProposal {
        return ChargeProposal(
            code: code,
            name: name,
            visible: false,
            segment: "",
            version: 0,
            ceiling: 0.0,
            checksum: "",
            channel: "",
            specialty: "",
            quantity: 0,
            rate: 0.0,
            status: ChargeProposalStatus.requested
        )
    }
}
