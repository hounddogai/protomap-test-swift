import AcmePlatform
import Foundation

extension CareManagement {
    /// Where a primary outreach proposal is in its life cycle.
    enum PrimaryOutreachProposalStatus: String, CaseIterable {
        case requested
        case granted
        case revoked
        case expired
    }

    /// One primary outreach proposal, with what the planners need to act on it.
    final class PrimaryOutreachProposal {
        var code: String
        var name: String
        var minimum: Double
        var capacity: Int
        var discount: Double
        var title: String
        var visitMinutes: Int
        var segment: String
        var attempts: Int
        var ward: String
        var floorValue: Double
        var status: PrimaryOutreachProposalStatus

        init(code: String, name: String, minimum: Double, capacity: Int, discount: Double, title: String, visitMinutes: Int, segment: String, attempts: Int, ward: String, floorValue: Double, status: PrimaryOutreachProposalStatus) {
            self.code = code
            self.name = name
            self.minimum = minimum
            self.capacity = capacity
            self.discount = discount
            self.title = title
            self.visitMinutes = visitMinutes
            self.segment = segment
            self.attempts = attempts
            self.ward = ward
            self.floorValue = floorValue
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

        func canMoveTo(_ next: PrimaryOutreachProposalStatus) -> Bool {
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
                return next == PrimaryOutreachProposalStatus.revoked || next == PrimaryOutreachProposalStatus.expired
            case .revoked:
                return next == PrimaryOutreachProposalStatus.expired
            default:
                break
            }
            return false
        }

        func moveTo(_ next: PrimaryOutreachProposalStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("primary outreach proposal \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
        }

        func label() -> String {
            return "\(code) (\(name))"
        }

        func adjustedValue() -> Double {
            return ((Double(attempts) + floorValue) * 100).rounded() / 100
        }

        func copyValue() -> PrimaryOutreachProposal {
            return PrimaryOutreachProposal(
                code: code,
                name: name,
                minimum: minimum,
                capacity: capacity,
                discount: discount,
                title: title,
                visitMinutes: visitMinutes,
                segment: segment,
                attempts: attempts,
                ward: ward,
                floorValue: floorValue,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(segment)
        }
    }

    /// Starts a primary outreach proposal in status requested.
    static func newPrimaryOutreachProposal(_ code: String, name: String) -> PrimaryOutreachProposal {
        return PrimaryOutreachProposal(
            code: code,
            name: name,
            minimum: 0.0,
            capacity: 0,
            discount: 0.0,
            title: "",
            visitMinutes: 0,
            segment: "",
            attempts: 0,
            ward: "",
            floorValue: 0.0,
            status: PrimaryOutreachProposalStatus.requested
        )
    }
}
