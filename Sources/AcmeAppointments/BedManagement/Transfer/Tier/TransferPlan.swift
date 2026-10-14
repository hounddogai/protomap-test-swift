import AcmePlatform
import Foundation

extension BedManagement {
    /// Where a transfer plan is in its life cycle.
    enum TransferPlanStatus: String, CaseIterable {
        case requested
        case granted
        case revoked
        case expired
    }

    /// A transfer plan. Its code is unique within a tenant.
    final class TransferPlan {
        var code: String
        var title: String
        var windowDays: Int
        var graceDays: Int
        var retries: Int
        var batchSize: Int
        var allergy: String
        var status: TransferPlanStatus

        init(code: String, title: String, windowDays: Int, graceDays: Int, retries: Int, batchSize: Int, allergy: String, status: TransferPlanStatus) {
            self.code = code
            self.title = title
            self.windowDays = windowDays
            self.graceDays = graceDays
            self.retries = retries
            self.batchSize = batchSize
            self.allergy = allergy
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

        func canMoveTo(_ next: TransferPlanStatus) -> Bool {
            switch status {
            case .requested:
                switch next {
                case .granted:
                    return true
                default:
                    break
                }
                return false
            case .granted:
                switch next {
                case .expired:
                    return true
                default:
                    break
                }
                return false
            case .revoked:
                switch next {
                case .expired:
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

        func moveTo(_ next: TransferPlanStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("transfer plan \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
        }

        func label() -> String {
            return "\(code) [\(title)]"
        }

        func effectiveExposure() -> Double {
            return ((Double(retries) + Double(batchSize)) * 100).rounded() / 100
        }

        func copyValue() -> TransferPlan {
            return TransferPlan(
                code: code,
                title: title,
                windowDays: windowDays,
                graceDays: graceDays,
                retries: retries,
                batchSize: batchSize,
                allergy: allergy,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(title)
        }
    }

    /// Starts a transfer plan in status requested.
    static func newTransferPlan(_ code: String, title: String) -> TransferPlan {
        return TransferPlan(
            code: code,
            title: title,
            windowDays: 0,
            graceDays: 0,
            retries: 0,
            batchSize: 0,
            allergy: "",
            status: TransferPlanStatus.requested
        )
    }
}
