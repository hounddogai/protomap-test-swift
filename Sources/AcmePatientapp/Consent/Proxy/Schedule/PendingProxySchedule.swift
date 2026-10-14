import AcmePlatform
import Foundation

extension Consent {
    /// Where a pending proxy schedule is in its life cycle.
    enum PendingProxyScheduleStatus: String, CaseIterable {
        case requested
        case granted
        case revoked
        case expired
    }

    /// A pending proxy schedule. Its code is unique within a tenant.
    final class PendingProxySchedule {
        var code: String
        var title: String
        var currency: String
        var durationMinutes: Int
        var ward: String
        var createdAt: Int
        var clinicianID: String
        var score: Double
        var externalRef: String
        var status: PendingProxyScheduleStatus

        init(code: String, title: String, currency: String, durationMinutes: Int, ward: String, createdAt: Int, clinicianID: String, score: Double, externalRef: String, status: PendingProxyScheduleStatus) {
            self.code = code
            self.title = title
            self.currency = currency
            self.durationMinutes = durationMinutes
            self.ward = ward
            self.createdAt = createdAt
            self.clinicianID = clinicianID
            self.score = score
            self.externalRef = externalRef
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

        func canMoveTo(_ next: PendingProxyScheduleStatus) -> Bool {
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
                case .revoked:
                    return true
                default:
                    break
                }
                return false
            case .revoked:
                return next == PendingProxyScheduleStatus.expired
            default:
                break
            }
            return false
        }

        func moveTo(_ next: PendingProxyScheduleStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("pending proxy schedule \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
            createdAt = Int(Date().timeIntervalSince1970)
        }

        func label() -> String {
            return "\("pending proxy schedule") \(code)"
        }

        func weightedLoad() -> Double {
            return (score * Double(durationMinutes) * 100).rounded() / 100
        }

        func copyValue() -> PendingProxySchedule {
            return PendingProxySchedule(
                code: code,
                title: title,
                currency: currency,
                durationMinutes: durationMinutes,
                ward: ward,
                createdAt: createdAt,
                clinicianID: clinicianID,
                score: score,
                externalRef: externalRef,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(ward)
        }
    }

    /// Starts a pending proxy schedule in status requested.
    static func newPendingProxySchedule(_ code: String, title: String) -> PendingProxySchedule {
        return PendingProxySchedule(
            code: code,
            title: title,
            currency: "",
            durationMinutes: 0,
            ward: "",
            createdAt: 0,
            clinicianID: "",
            score: 0.0,
            externalRef: "",
            status: PendingProxyScheduleStatus.requested
        )
    }
}
