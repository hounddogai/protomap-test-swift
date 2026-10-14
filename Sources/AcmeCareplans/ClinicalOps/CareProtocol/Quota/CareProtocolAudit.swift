import AcmePlatform
import Foundation

extension ClinicalOps {
    /// Where a care protocol audit is in its life cycle.
    enum CareProtocolAuditStatus: String, CaseIterable {
        case requested
        case granted
        case revoked
        case expired
    }

    /// The record of a care protocol audit and its current status.
    final class CareProtocolAudit {
        var code: String
        var title: String
        var acuity: Int
        var ward: String
        var threshold: Double
        var windowDays: Int
        var score: Double
        var status: CareProtocolAuditStatus

        init(code: String, title: String, acuity: Int, ward: String, threshold: Double, windowDays: Int, score: Double, status: CareProtocolAuditStatus) {
            self.code = code
            self.title = title
            self.acuity = acuity
            self.ward = ward
            self.threshold = threshold
            self.windowDays = windowDays
            self.score = score
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

        func canMoveTo(_ next: CareProtocolAuditStatus) -> Bool {
            switch status {
            case .requested:
                return next == CareProtocolAuditStatus.granted || next == CareProtocolAuditStatus.revoked
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

        func moveTo(_ next: CareProtocolAuditStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("care protocol audit \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
        }

        func label() -> String {
            return "\(code) [\(title)]"
        }

        func netVolume() -> Double {
            return (Double(windowDays) * score * 100).rounded() / 100
        }

        func copyValue() -> CareProtocolAudit {
            return CareProtocolAudit(
                code: code,
                title: title,
                acuity: acuity,
                ward: ward,
                threshold: threshold,
                windowDays: windowDays,
                score: score,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(ward)
        }
    }

    /// Starts a care protocol audit in status requested.
    static func newCareProtocolAudit(_ code: String, title: String) -> CareProtocolAudit {
        return CareProtocolAudit(
            code: code,
            title: title,
            acuity: 0,
            ward: "",
            threshold: 0.0,
            windowDays: 0,
            score: 0.0,
            status: CareProtocolAuditStatus.requested
        )
    }
}
