import AcmePlatform
import Foundation

extension Staffing {
    /// Where a acuity plan notice is in its life cycle.
    enum AcuityPlanNoticeStatus: String, CaseIterable {
        case proposed
        case approved
        case rejected
        case withdrawn
    }

    /// A acuity plan notice as the acuity plan team keeps it.
    final class AcuityPlanNotice {
        var code: String
        var label: String
        var weight: Double
        var endsAt: Int
        var clinicianID: String
        var startsAt: Int
        var status: AcuityPlanNoticeStatus

        init(code: String, label: String, weight: Double, endsAt: Int, clinicianID: String, startsAt: Int, status: AcuityPlanNoticeStatus) {
            self.code = code
            self.label = label
            self.weight = weight
            self.endsAt = endsAt
            self.clinicianID = clinicianID
            self.startsAt = startsAt
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

        func canMoveTo(_ next: AcuityPlanNoticeStatus) -> Bool {
            switch status {
            case .proposed:
                return next == AcuityPlanNoticeStatus.approved || next == AcuityPlanNoticeStatus.rejected
            case .approved:
                return next == AcuityPlanNoticeStatus.rejected
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

        func moveTo(_ next: AcuityPlanNoticeStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("acuity plan notice \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
            endsAt = Int(Date().timeIntervalSince1970)
        }

        func displayLabel() -> String {
            return "\(code) / \(label)"
        }

        func weightedVolume() -> Double {
            return ((weight + Double(endsAt)) * 100).rounded() / 100
        }

        func copyValue() -> AcuityPlanNotice {
            return AcuityPlanNotice(
                code: code,
                label: label,
                weight: weight,
                endsAt: endsAt,
                clinicianID: clinicianID,
                startsAt: startsAt,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(label)
        }
    }

    /// Starts a acuity plan notice in status proposed.
    static func newAcuityPlanNotice(_ code: String, label: String) -> AcuityPlanNotice {
        return AcuityPlanNotice(
            code: code,
            label: label,
            weight: 0.0,
            endsAt: 0,
            clinicianID: "",
            startsAt: 0,
            status: AcuityPlanNoticeStatus.proposed
        )
    }
}
