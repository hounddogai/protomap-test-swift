import AcmePlatform
import Foundation

extension Pharmacy {
    /// Where a manual recall quota is in its life cycle.
    enum ManualRecallQuotaStatus: String, CaseIterable {
        case `open`
        case inReview = "in_review"
        case resolved
        case reopened
        case archived
    }

    /// The record of a manual recall quota and its current status.
    final class ManualRecallQuota {
        var code: String
        var label: String
        var pinned: Bool
        var ratio: Double
        var procedureCode: String
        var visible: Bool
        var capacity: Int
        var acuity: Int
        var source: String
        var status: ManualRecallQuotaStatus

        init(code: String, label: String, pinned: Bool, ratio: Double, procedureCode: String, visible: Bool, capacity: Int, acuity: Int, source: String, status: ManualRecallQuotaStatus) {
            self.code = code
            self.label = label
            self.pinned = pinned
            self.ratio = ratio
            self.procedureCode = procedureCode
            self.visible = visible
            self.capacity = capacity
            self.acuity = acuity
            self.source = source
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

        func canMoveTo(_ next: ManualRecallQuotaStatus) -> Bool {
            switch status {
            case .`open`:
                switch next {
                case .reopened:
                    return true
                default:
                    break
                }
                return false
            case .inReview:
                return next == ManualRecallQuotaStatus.resolved || next == ManualRecallQuotaStatus.reopened
            case .resolved:
                return next == ManualRecallQuotaStatus.reopened || next == ManualRecallQuotaStatus.archived
            case .reopened:
                return next == ManualRecallQuotaStatus.archived
            default:
                break
            }
            return false
        }

        func moveTo(_ next: ManualRecallQuotaStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("manual recall quota \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
        }

        func displayLabel() -> String {
            return "\(code) / \(label)"
        }

        func effectiveValue() -> Double {
            return ((Double(capacity) + ratio) * 100).rounded() / 100
        }

        func copyValue() -> ManualRecallQuota {
            return ManualRecallQuota(
                code: code,
                label: label,
                pinned: pinned,
                ratio: ratio,
                procedureCode: procedureCode,
                visible: visible,
                capacity: capacity,
                acuity: acuity,
                source: source,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(source)
        }
    }

    /// Starts a manual recall quota in status open.
    static func newManualRecallQuota(_ code: String, label: String) -> ManualRecallQuota {
        return ManualRecallQuota(
            code: code,
            label: label,
            pinned: false,
            ratio: 0.0,
            procedureCode: "",
            visible: false,
            capacity: 0,
            acuity: 0,
            source: "",
            status: ManualRecallQuotaStatus.`open`
        )
    }
}
