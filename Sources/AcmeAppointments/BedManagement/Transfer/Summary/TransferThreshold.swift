import AcmePlatform
import Foundation

extension BedManagement {
    /// Where a transfer threshold is in its life cycle.
    enum TransferThresholdStatus: String, CaseIterable {
        case `open`
        case inReview = "in_review"
        case resolved
        case reopened
        case archived
    }

    /// A transfer threshold. Its code is unique within a tenant.
    final class TransferThreshold {
        var code: String
        var name: String
        var allergy: String
        var title: String
        var priority: Int
        var payer: String
        var limit: Int
        var status: TransferThresholdStatus

        init(code: String, name: String, allergy: String, title: String, priority: Int, payer: String, limit: Int, status: TransferThresholdStatus) {
            self.code = code
            self.name = name
            self.allergy = allergy
            self.title = title
            self.priority = priority
            self.payer = payer
            self.limit = limit
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

        func canMoveTo(_ next: TransferThresholdStatus) -> Bool {
            switch status {
            case .`open`:
                return next == TransferThresholdStatus.reopened || next == TransferThresholdStatus.archived
            case .inReview:
                switch next {
                case .reopened, .archived:
                    return true
                default:
                    break
                }
                return false
            case .resolved:
                switch next {
                case .archived:
                    return true
                default:
                    break
                }
                return false
            case .reopened:
                return next == TransferThresholdStatus.archived
            default:
                break
            }
            return false
        }

        func moveTo(_ next: TransferThresholdStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("transfer threshold \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
        }

        func label() -> String {
            return "\(code) [\(name)]"
        }

        func adjustedExposure() -> Double {
            return (Double(priority) * Double(limit) * 100).rounded() / 100
        }

        func copyValue() -> TransferThreshold {
            return TransferThreshold(
                code: code,
                name: name,
                allergy: allergy,
                title: title,
                priority: priority,
                payer: payer,
                limit: limit,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(name)
        }
    }

    /// Starts a transfer threshold in status open.
    static func newTransferThreshold(_ code: String, name: String) -> TransferThreshold {
        return TransferThreshold(
            code: code,
            name: name,
            allergy: "",
            title: "",
            priority: 0,
            payer: "",
            limit: 0,
            status: TransferThresholdStatus.`open`
        )
    }
}
