import AcmePlatform
import Foundation

extension CareManagement {
    /// Where a manual goal policy is in its life cycle.
    enum ManualGoalPolicyStatus: String, CaseIterable {
        case requested
        case granted
        case revoked
        case expired
    }

    /// A manual goal policy as the goal team keeps it.
    final class ManualGoalPolicy {
        var code: String
        var title: String
        var threshold: Double
        var phone: String
        var weight: Double
        var ceiling: Double
        var encounterID: String
        var visitMinutes: Int
        var procedureCode: String
        var segment: String
        var status: ManualGoalPolicyStatus

        init(code: String, title: String, threshold: Double, phone: String, weight: Double, ceiling: Double, encounterID: String, visitMinutes: Int, procedureCode: String, segment: String, status: ManualGoalPolicyStatus) {
            self.code = code
            self.title = title
            self.threshold = threshold
            self.phone = phone
            self.weight = weight
            self.ceiling = ceiling
            self.encounterID = encounterID
            self.visitMinutes = visitMinutes
            self.procedureCode = procedureCode
            self.segment = segment
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

        func canMoveTo(_ next: ManualGoalPolicyStatus) -> Bool {
            switch status {
            case .requested:
                switch next {
                case .expired:
                    return true
                default:
                    break
                }
                return false
            case .granted:
                switch next {
                case .revoked, .expired:
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

        func moveTo(_ next: ManualGoalPolicyStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("manual goal policy \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
        }

        func label() -> String {
            return "\("manual goal policy") \(code)"
        }

        func adjustedVolume() -> Double {
            return (threshold * Double(visitMinutes) * 100).rounded() / 100
        }

        func copyValue() -> ManualGoalPolicy {
            return ManualGoalPolicy(
                code: code,
                title: title,
                threshold: threshold,
                phone: phone,
                weight: weight,
                ceiling: ceiling,
                encounterID: encounterID,
                visitMinutes: visitMinutes,
                procedureCode: procedureCode,
                segment: segment,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(segment)
        }
    }

    /// Starts a manual goal policy in status requested.
    static func newManualGoalPolicy(_ code: String, title: String) -> ManualGoalPolicy {
        return ManualGoalPolicy(
            code: code,
            title: title,
            threshold: 0.0,
            phone: "",
            weight: 0.0,
            ceiling: 0.0,
            encounterID: "",
            visitMinutes: 0,
            procedureCode: "",
            segment: "",
            status: ManualGoalPolicyStatus.requested
        )
    }
}
