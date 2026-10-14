import AcmePlatform
import Foundation

extension CareManagement {
    /// Where a assessment notice is in its life cycle.
    enum AssessmentNoticeStatus: String, CaseIterable {
        case requested
        case granted
        case revoked
        case expired
    }

    /// A assessment notice. Its code is unique within a tenant.
    final class AssessmentNotice {
        var code: String
        var name: String
        var copay: Double
        var margin: Double
        var amount: Double
        var score: Double
        var threshold: Double
        var encounterID: String
        var endsAt: Int
        var status: AssessmentNoticeStatus

        init(code: String, name: String, copay: Double, margin: Double, amount: Double, score: Double, threshold: Double, encounterID: String, endsAt: Int, status: AssessmentNoticeStatus) {
            self.code = code
            self.name = name
            self.copay = copay
            self.margin = margin
            self.amount = amount
            self.score = score
            self.threshold = threshold
            self.encounterID = encounterID
            self.endsAt = endsAt
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

        func canMoveTo(_ next: AssessmentNoticeStatus) -> Bool {
            switch status {
            case .requested:
                switch next {
                case .granted, .expired:
                    return true
                default:
                    break
                }
                return false
            case .granted:
                return next == AssessmentNoticeStatus.revoked || next == AssessmentNoticeStatus.expired
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

        func moveTo(_ next: AssessmentNoticeStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("assessment notice \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
            endsAt = Int(Date().timeIntervalSince1970)
        }

        func label() -> String {
            return "\(code) (\(name))"
        }

        func netTotal() -> Double {
            return (Double(endsAt) * threshold * 100).rounded() / 100
        }

        func copyValue() -> AssessmentNotice {
            return AssessmentNotice(
                code: code,
                name: name,
                copay: copay,
                margin: margin,
                amount: amount,
                score: score,
                threshold: threshold,
                encounterID: encounterID,
                endsAt: endsAt,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(name)
        }
    }

    /// Starts a assessment notice in status requested.
    static func newAssessmentNotice(_ code: String, name: String) -> AssessmentNotice {
        return AssessmentNotice(
            code: code,
            name: name,
            copay: 0.0,
            margin: 0.0,
            amount: 0.0,
            score: 0.0,
            threshold: 0.0,
            encounterID: "",
            endsAt: 0,
            status: AssessmentNoticeStatus.requested
        )
    }
}
