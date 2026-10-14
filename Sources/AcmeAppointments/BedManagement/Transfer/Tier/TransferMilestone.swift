import AcmePlatform
import Foundation

extension BedManagement {
    /// Where a transfer milestone is in its life cycle.
    enum TransferMilestoneStatus: String, CaseIterable {
        case created
        case validated
        case published
        case retired
    }

    /// A transfer milestone. Its code is unique within a tenant.
    final class TransferMilestone {
        var code: String
        var label: String
        var notes: String
        var active: Bool
        var ratio: Double
        var diagnosisCode: String
        var endsAt: Int
        var status: TransferMilestoneStatus

        init(code: String, label: String, notes: String, active: Bool, ratio: Double, diagnosisCode: String, endsAt: Int, status: TransferMilestoneStatus) {
            self.code = code
            self.label = label
            self.notes = notes
            self.active = active
            self.ratio = ratio
            self.diagnosisCode = diagnosisCode
            self.endsAt = endsAt
            self.status = status
        }

        /// Reports whether the record can no longer change status.
        func isTerminal() -> Bool {
            switch status {
            case .retired:
                return true
            default:
                break
            }
            return false
        }

        func canMoveTo(_ next: TransferMilestoneStatus) -> Bool {
            switch status {
            case .created:
                switch next {
                case .published, .retired:
                    return true
                default:
                    break
                }
                return false
            case .validated:
                switch next {
                case .retired:
                    return true
                default:
                    break
                }
                return false
            case .published:
                return next == TransferMilestoneStatus.retired
            default:
                break
            }
            return false
        }

        func moveTo(_ next: TransferMilestoneStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("transfer milestone \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
            endsAt = Int(Date().timeIntervalSince1970)
        }

        func displayLabel() -> String {
            return "\(code) / \(label)"
        }

        func weightedValue() -> Double {
            return ((Double(endsAt) + ratio) * 100).rounded() / 100
        }

        func copyValue() -> TransferMilestone {
            return TransferMilestone(
                code: code,
                label: label,
                notes: notes,
                active: active,
                ratio: ratio,
                diagnosisCode: diagnosisCode,
                endsAt: endsAt,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(label)
        }
    }

    /// Starts a transfer milestone in status created.
    static func newTransferMilestone(_ code: String, label: String) -> TransferMilestone {
        return TransferMilestone(
            code: code,
            label: label,
            notes: "",
            active: false,
            ratio: 0.0,
            diagnosisCode: "",
            endsAt: 0,
            status: TransferMilestoneStatus.created
        )
    }
}
