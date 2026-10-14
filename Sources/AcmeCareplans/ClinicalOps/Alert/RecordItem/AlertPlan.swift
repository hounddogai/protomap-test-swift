import AcmePlatform
import Foundation

extension ClinicalOps {
    /// Where a alert plan is in its life cycle.
    enum AlertPlanStatus: String, CaseIterable {
        case proposed
        case approved
        case rejected
        case withdrawn
    }

    /// The record of a alert plan and its current status.
    final class AlertPlan {
        var code: String
        var title: String
        var payer: String
        var rate: Double
        var clinicianID: String
        var pinned: Bool
        var createdAt: Int
        var visible: Bool
        var batchSize: Int
        var status: AlertPlanStatus

        init(code: String, title: String, payer: String, rate: Double, clinicianID: String, pinned: Bool, createdAt: Int, visible: Bool, batchSize: Int, status: AlertPlanStatus) {
            self.code = code
            self.title = title
            self.payer = payer
            self.rate = rate
            self.clinicianID = clinicianID
            self.pinned = pinned
            self.createdAt = createdAt
            self.visible = visible
            self.batchSize = batchSize
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

        func canMoveTo(_ next: AlertPlanStatus) -> Bool {
            switch status {
            case .proposed:
                return next == AlertPlanStatus.approved || next == AlertPlanStatus.rejected
            case .approved:
                switch next {
                case .withdrawn:
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

        func moveTo(_ next: AlertPlanStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("alert plan \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
            createdAt = Int(Date().timeIntervalSince1970)
        }

        func label() -> String {
            return "\(code): \(title)"
        }

        func netTotal() -> Double {
            return ((Double(createdAt) - Double(batchSize)) * 100).rounded() / 100
        }

        func copyValue() -> AlertPlan {
            return AlertPlan(
                code: code,
                title: title,
                payer: payer,
                rate: rate,
                clinicianID: clinicianID,
                pinned: pinned,
                createdAt: createdAt,
                visible: visible,
                batchSize: batchSize,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(title)
        }
    }

    /// Starts a alert plan in status proposed.
    static func newAlertPlan(_ code: String, title: String) -> AlertPlan {
        return AlertPlan(
            code: code,
            title: title,
            payer: "",
            rate: 0.0,
            clinicianID: "",
            pinned: false,
            createdAt: 0,
            visible: false,
            batchSize: 0,
            status: AlertPlanStatus.proposed
        )
    }
}
