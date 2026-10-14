import AcmePlatform
import Foundation

extension Imaging {
    /// Where a care protocol digest is in its life cycle.
    enum CareProtocolDigestStatus: String, CaseIterable {
        case proposed
        case approved
        case rejected
        case withdrawn
    }

    /// A care protocol digest as the care protocol team keeps it.
    final class CareProtocolDigest {
        var code: String
        var label: String
        var name: String
        var summary: String
        var procedureCode: String
        var amount: Double
        var status: CareProtocolDigestStatus

        init(code: String, label: String, name: String, summary: String, procedureCode: String, amount: Double, status: CareProtocolDigestStatus) {
            self.code = code
            self.label = label
            self.name = name
            self.summary = summary
            self.procedureCode = procedureCode
            self.amount = amount
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

        func canMoveTo(_ next: CareProtocolDigestStatus) -> Bool {
            switch status {
            case .proposed:
                switch next {
                case .approved, .withdrawn:
                    return true
                default:
                    break
                }
                return false
            case .approved:
                return next == CareProtocolDigestStatus.withdrawn
            case .rejected:
                return next == CareProtocolDigestStatus.withdrawn
            default:
                break
            }
            return false
        }

        func moveTo(_ next: CareProtocolDigestStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("care protocol digest \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
        }

        func displayLabel() -> String {
            return "\(code) (\(label))"
        }

        func measuredValue() -> Double {
            return amount
        }

        func copyValue() -> CareProtocolDigest {
            return CareProtocolDigest(
                code: code,
                label: label,
                name: name,
                summary: summary,
                procedureCode: procedureCode,
                amount: amount,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(label)
        }
    }

    /// Starts a care protocol digest in status proposed.
    static func newCareProtocolDigest(_ code: String, label: String) -> CareProtocolDigest {
        return CareProtocolDigest(
            code: code,
            label: label,
            name: "",
            summary: "",
            procedureCode: "",
            amount: 0.0,
            status: CareProtocolDigestStatus.proposed
        )
    }
}
