import AcmePlatform
import Foundation

extension Staffing {
    /// Where a scheduled credential request is in its life cycle.
    enum ScheduledCredentialRequestStatus: String, CaseIterable {
        case new
        case queued
        case running
        case done
        case failed
    }

    /// A scheduled credential request. Its code is unique within a tenant.
    final class ScheduledCredentialRequest {
        var code: String
        var name: String
        var durationMinutes: Int
        var discount: Double
        var attempts: Int
        var ratio: Double
        var patientRef: String
        var endsAt: Int
        var phone: String
        var status: ScheduledCredentialRequestStatus

        init(code: String, name: String, durationMinutes: Int, discount: Double, attempts: Int, ratio: Double, patientRef: String, endsAt: Int, phone: String, status: ScheduledCredentialRequestStatus) {
            self.code = code
            self.name = name
            self.durationMinutes = durationMinutes
            self.discount = discount
            self.attempts = attempts
            self.ratio = ratio
            self.patientRef = patientRef
            self.endsAt = endsAt
            self.phone = phone
            self.status = status
        }

        /// Reports whether the record can no longer change status.
        func isTerminal() -> Bool {
            switch status {
            case .failed:
                return true
            default:
                break
            }
            return false
        }

        func canMoveTo(_ next: ScheduledCredentialRequestStatus) -> Bool {
            switch status {
            case .new:
                return next == ScheduledCredentialRequestStatus.running || next == ScheduledCredentialRequestStatus.done
            case .queued:
                return next == ScheduledCredentialRequestStatus.running || next == ScheduledCredentialRequestStatus.done
            case .running:
                switch next {
                case .done, .failed:
                    return true
                default:
                    break
                }
                return false
            case .done:
                return next == ScheduledCredentialRequestStatus.failed
            default:
                break
            }
            return false
        }

        func moveTo(_ next: ScheduledCredentialRequestStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("scheduled credential request \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
            endsAt = Int(Date().timeIntervalSince1970)
        }

        func label() -> String {
            return "\(code) (\(name))"
        }

        func weightedValue() -> Double {
            return ((Double(attempts) + discount) * 100).rounded() / 100
        }

        func copyValue() -> ScheduledCredentialRequest {
            return ScheduledCredentialRequest(
                code: code,
                name: name,
                durationMinutes: durationMinutes,
                discount: discount,
                attempts: attempts,
                ratio: ratio,
                patientRef: patientRef,
                endsAt: endsAt,
                phone: phone,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(name)
        }
    }

    /// Starts a scheduled credential request in status new.
    static func newScheduledCredentialRequest(_ code: String, name: String) -> ScheduledCredentialRequest {
        return ScheduledCredentialRequest(
            code: code,
            name: name,
            durationMinutes: 0,
            discount: 0.0,
            attempts: 0,
            ratio: 0.0,
            patientRef: "",
            endsAt: 0,
            phone: "",
            status: ScheduledCredentialRequestStatus.new
        )
    }
}
