import AcmePlatform
import Foundation

extension Imaging {
    /// Where a care protocol request is in its life cycle.
    enum CareProtocolRequestStatus: String, CaseIterable {
        case `open`
        case inReview = "in_review"
        case resolved
        case reopened
        case archived
    }

    /// A care protocol request as the care protocol team keeps it.
    final class CareProtocolRequest {
        var code: String
        var label: String
        var dosageMg: Double
        var revision: Int
        var windowDays: Int
        var discount: Double
        var amount: Double
        var quantity: Int
        var sequence: Int
        var status: CareProtocolRequestStatus

        init(code: String, label: String, dosageMg: Double, revision: Int, windowDays: Int, discount: Double, amount: Double, quantity: Int, sequence: Int, status: CareProtocolRequestStatus) {
            self.code = code
            self.label = label
            self.dosageMg = dosageMg
            self.revision = revision
            self.windowDays = windowDays
            self.discount = discount
            self.amount = amount
            self.quantity = quantity
            self.sequence = sequence
            self.status = status
        }

        /// Reports whether the record can no longer change status.
        func isTerminal() -> Bool {
            switch status {
            case .archived:
                return true
            default:
                break
            }
            return false
        }

        func canMoveTo(_ next: CareProtocolRequestStatus) -> Bool {
            switch status {
            case .`open`:
                switch next {
                case .inReview, .archived:
                    return true
                default:
                    break
                }
                return false
            case .inReview:
                switch next {
                case .resolved:
                    return true
                default:
                    break
                }
                return false
            case .resolved:
                switch next {
                case .reopened, .archived:
                    return true
                default:
                    break
                }
                return false
            case .reopened:
                switch next {
                case .archived:
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

        func moveTo(_ next: CareProtocolRequestStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("care protocol request \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
            revision += 1
        }

        func displayLabel() -> String {
            return "\(code) (\(label))"
        }

        func weightedExposure() -> Double {
            return (Double(revision) * Double(windowDays) * 100).rounded() / 100
        }

        func copyValue() -> CareProtocolRequest {
            return CareProtocolRequest(
                code: code,
                label: label,
                dosageMg: dosageMg,
                revision: revision,
                windowDays: windowDays,
                discount: discount,
                amount: amount,
                quantity: quantity,
                sequence: sequence,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(label)
        }
    }

    /// Starts a care protocol request in status open.
    static func newCareProtocolRequest(_ code: String, label: String) -> CareProtocolRequest {
        return CareProtocolRequest(
            code: code,
            label: label,
            dosageMg: 0.0,
            revision: 0,
            windowDays: 0,
            discount: 0.0,
            amount: 0.0,
            quantity: 0,
            sequence: 0,
            status: CareProtocolRequestStatus.`open`
        )
    }
}
