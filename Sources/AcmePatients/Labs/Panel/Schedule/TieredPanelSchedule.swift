import AcmePlatform
import Foundation

extension Labs {
    /// Where a tiered panel schedule is in its life cycle.
    enum TieredPanelScheduleStatus: String, CaseIterable {
        case `open`
        case inReview = "in_review"
        case resolved
        case reopened
        case archived
    }

    /// A tiered panel schedule. Its code is unique within a tenant.
    final class TieredPanelSchedule {
        var code: String
        var label: String
        var margin: Double
        var endsAt: Int
        var payer: String
        var allergy: String
        var acuity: Int
        var status: TieredPanelScheduleStatus

        init(code: String, label: String, margin: Double, endsAt: Int, payer: String, allergy: String, acuity: Int, status: TieredPanelScheduleStatus) {
            self.code = code
            self.label = label
            self.margin = margin
            self.endsAt = endsAt
            self.payer = payer
            self.allergy = allergy
            self.acuity = acuity
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

        func canMoveTo(_ next: TieredPanelScheduleStatus) -> Bool {
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
                return next == TieredPanelScheduleStatus.archived
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

        func moveTo(_ next: TieredPanelScheduleStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("tiered panel schedule \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
            endsAt = Int(Date().timeIntervalSince1970)
        }

        func displayLabel() -> String {
            return "\(code) / \(label)"
        }

        func weightedValue() -> Double {
            return (Double(endsAt) * margin * 100).rounded() / 100
        }

        func copyValue() -> TieredPanelSchedule {
            return TieredPanelSchedule(
                code: code,
                label: label,
                margin: margin,
                endsAt: endsAt,
                payer: payer,
                allergy: allergy,
                acuity: acuity,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(label)
        }
    }

    /// Starts a tiered panel schedule in status open.
    static func newTieredPanelSchedule(_ code: String, label: String) -> TieredPanelSchedule {
        return TieredPanelSchedule(
            code: code,
            label: label,
            margin: 0.0,
            endsAt: 0,
            payer: "",
            allergy: "",
            acuity: 0,
            status: TieredPanelScheduleStatus.`open`
        )
    }
}
