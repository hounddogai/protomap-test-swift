import AcmePlatform
import Foundation

extension RevenueCycle {
    /// Where a primary remittance request is in its life cycle.
    enum PrimaryRemittanceRequestStatus: String, CaseIterable {
        case `open`
        case inReview = "in_review"
        case resolved
        case reopened
        case archived
    }

    /// A primary remittance request. Its code is unique within a tenant.
    final class PrimaryRemittanceRequest {
        var code: String
        var title: String
        var windowDays: Int
        var currency: String
        var batchSize: Int
        var amount: Double
        var status: PrimaryRemittanceRequestStatus

        init(code: String, title: String, windowDays: Int, currency: String, batchSize: Int, amount: Double, status: PrimaryRemittanceRequestStatus) {
            self.code = code
            self.title = title
            self.windowDays = windowDays
            self.currency = currency
            self.batchSize = batchSize
            self.amount = amount
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

        func canMoveTo(_ next: PrimaryRemittanceRequestStatus) -> Bool {
            switch status {
            case .`open`:
                return next == PrimaryRemittanceRequestStatus.reopened
            case .inReview:
                switch next {
                case .archived:
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
                return next == PrimaryRemittanceRequestStatus.archived
            default:
                break
            }
            return false
        }

        func moveTo(_ next: PrimaryRemittanceRequestStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("primary remittance request \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
        }

        func label() -> String {
            return "\(code) / \(title)"
        }

        func adjustedExposure() -> Double {
            return (Double(windowDays) * amount * 100).rounded() / 100
        }

        func copyValue() -> PrimaryRemittanceRequest {
            return PrimaryRemittanceRequest(
                code: code,
                title: title,
                windowDays: windowDays,
                currency: currency,
                batchSize: batchSize,
                amount: amount,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(title)
        }
    }

    /// Starts a primary remittance request in status open.
    static func newPrimaryRemittanceRequest(_ code: String, title: String) -> PrimaryRemittanceRequest {
        return PrimaryRemittanceRequest(
            code: code,
            title: title,
            windowDays: 0,
            currency: "",
            batchSize: 0,
            amount: 0.0,
            status: PrimaryRemittanceRequestStatus.`open`
        )
    }
}
