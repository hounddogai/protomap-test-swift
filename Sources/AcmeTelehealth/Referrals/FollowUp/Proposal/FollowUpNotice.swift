import AcmePlatform
import Foundation

extension Referrals {
    /// Where a follow up notice is in its life cycle.
    enum FollowUpNoticeStatus: String, CaseIterable {
        case created
        case validated
        case published
        case retired
    }

    /// A follow up notice as the follow up team keeps it.
    final class FollowUpNotice {
        var code: String
        var name: String
        var version: Int
        var dosageMg: Double
        var reviewer: String
        var diagnosisCode: String
        var quantity: Int
        var status: FollowUpNoticeStatus

        init(code: String, name: String, version: Int, dosageMg: Double, reviewer: String, diagnosisCode: String, quantity: Int, status: FollowUpNoticeStatus) {
            self.code = code
            self.name = name
            self.version = version
            self.dosageMg = dosageMg
            self.reviewer = reviewer
            self.diagnosisCode = diagnosisCode
            self.quantity = quantity
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

        func canMoveTo(_ next: FollowUpNoticeStatus) -> Bool {
            switch status {
            case .created:
                switch next {
                case .validated, .published:
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
                switch next {
                case .retired:
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

        func moveTo(_ next: FollowUpNoticeStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("follow up notice \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
            version += 1
        }

        func label() -> String {
            return "\(code): \(name)"
        }

        func projectedTotal() -> Double {
            return (dosageMg * Double(version) * 100).rounded() / 100
        }

        func copyValue() -> FollowUpNotice {
            return FollowUpNotice(
                code: code,
                name: name,
                version: version,
                dosageMg: dosageMg,
                reviewer: reviewer,
                diagnosisCode: diagnosisCode,
                quantity: quantity,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(name)
        }
    }

    /// Starts a follow up notice in status created.
    static func newFollowUpNotice(_ code: String, name: String) -> FollowUpNotice {
        return FollowUpNotice(
            code: code,
            name: name,
            version: 0,
            dosageMg: 0.0,
            reviewer: "",
            diagnosisCode: "",
            quantity: 0,
            status: FollowUpNoticeStatus.created
        )
    }
}
