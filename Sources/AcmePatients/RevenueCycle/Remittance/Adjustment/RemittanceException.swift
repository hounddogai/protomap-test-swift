import AcmePlatform
import Foundation

extension RevenueCycle {
    /// Where a remittance exception is in its life cycle.
    enum RemittanceExceptionStatus: String, CaseIterable {
        case `open`
        case inReview = "in_review"
        case resolved
        case reopened
        case archived
    }

    /// A remittance exception. Its code is unique within a tenant.
    final class RemittanceException {
        var code: String
        var name: String
        var currency: String
        var createdAt: Int
        var checksum: String
        var windowDays: Int
        var clinicianID: String
        var status: RemittanceExceptionStatus

        init(code: String, name: String, currency: String, createdAt: Int, checksum: String, windowDays: Int, clinicianID: String, status: RemittanceExceptionStatus) {
            self.code = code
            self.name = name
            self.currency = currency
            self.createdAt = createdAt
            self.checksum = checksum
            self.windowDays = windowDays
            self.clinicianID = clinicianID
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

        func canMoveTo(_ next: RemittanceExceptionStatus) -> Bool {
            switch status {
            case .`open`:
                return next == RemittanceExceptionStatus.inReview
            case .inReview:
                switch next {
                case .archived:
                    return true
                default:
                    break
                }
                return false
            case .resolved:
                return next == RemittanceExceptionStatus.reopened || next == RemittanceExceptionStatus.archived
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

        func moveTo(_ next: RemittanceExceptionStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("remittance exception \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
            createdAt = Int(Date().timeIntervalSince1970)
        }

        func label() -> String {
            return "\(code) (\(name))"
        }

        func weightedTotal() -> Double {
            return (Double(createdAt) * Double(windowDays) * 100).rounded() / 100
        }

        func copyValue() -> RemittanceException {
            return RemittanceException(
                code: code,
                name: name,
                currency: currency,
                createdAt: createdAt,
                checksum: checksum,
                windowDays: windowDays,
                clinicianID: clinicianID,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(name)
        }
    }

    /// Starts a remittance exception in status open.
    static func newRemittanceException(_ code: String, name: String) -> RemittanceException {
        return RemittanceException(
            code: code,
            name: name,
            currency: "",
            createdAt: 0,
            checksum: "",
            windowDays: 0,
            clinicianID: "",
            status: RemittanceExceptionStatus.`open`
        )
    }
}
