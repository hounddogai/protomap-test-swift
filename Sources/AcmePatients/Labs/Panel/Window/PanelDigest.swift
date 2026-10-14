import AcmePlatform
import Foundation

extension Labs {
    /// Where a panel digest is in its life cycle.
    enum PanelDigestStatus: String, CaseIterable {
        case proposed
        case approved
        case rejected
        case withdrawn
    }

    /// One panel digest, with what the planners need to act on it.
    final class PanelDigest {
        var code: String
        var name: String
        var amount: Double
        var clinicianID: String
        var description: String
        var ratio: Double
        var status: PanelDigestStatus

        init(code: String, name: String, amount: Double, clinicianID: String, description: String, ratio: Double, status: PanelDigestStatus) {
            self.code = code
            self.name = name
            self.amount = amount
            self.clinicianID = clinicianID
            self.description = description
            self.ratio = ratio
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

        func canMoveTo(_ next: PanelDigestStatus) -> Bool {
            switch status {
            case .proposed:
                switch next {
                case .approved, .rejected:
                    return true
                default:
                    break
                }
                return false
            case .approved:
                switch next {
                case .rejected:
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

        func moveTo(_ next: PanelDigestStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("panel digest \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
        }

        func label() -> String {
            return "\("panel digest") \(code)"
        }

        func projectedLoad() -> Double {
            return (amount * ratio * 100).rounded() / 100
        }

        func copyValue() -> PanelDigest {
            return PanelDigest(
                code: code,
                name: name,
                amount: amount,
                clinicianID: clinicianID,
                description: description,
                ratio: ratio,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(name)
        }
    }

    /// Starts a panel digest in status proposed.
    static func newPanelDigest(_ code: String, name: String) -> PanelDigest {
        return PanelDigest(
            code: code,
            name: name,
            amount: 0.0,
            clinicianID: "",
            description: "",
            ratio: 0.0,
            status: PanelDigestStatus.proposed
        )
    }
}
