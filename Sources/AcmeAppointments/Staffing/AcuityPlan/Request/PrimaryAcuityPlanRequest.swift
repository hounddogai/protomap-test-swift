import AcmePlatform
import Foundation

extension Staffing {
    /// Where a primary acuity plan request is in its life cycle.
    enum PrimaryAcuityPlanRequestStatus: String, CaseIterable {
        case idle
        case warming
        case ready
        case draining
        case stopped
    }

    /// One primary acuity plan request, with what the planners need to act on it.
    final class PrimaryAcuityPlanRequest {
        var code: String
        var name: String
        var limit: Int
        var durationMinutes: Int
        var patientRef: String
        var expiresAt: Int
        var active: Bool
        var contactEmail: String
        var visible: Bool
        var endsAt: Int
        var priority: Int
        var status: PrimaryAcuityPlanRequestStatus

        init(code: String, name: String, limit: Int, durationMinutes: Int, patientRef: String, expiresAt: Int, active: Bool, contactEmail: String, visible: Bool, endsAt: Int, priority: Int, status: PrimaryAcuityPlanRequestStatus) {
            self.code = code
            self.name = name
            self.limit = limit
            self.durationMinutes = durationMinutes
            self.patientRef = patientRef
            self.expiresAt = expiresAt
            self.active = active
            self.contactEmail = contactEmail
            self.visible = visible
            self.endsAt = endsAt
            self.priority = priority
            self.status = status
        }

        /// Reports whether the record can no longer change status.
        func isTerminal() -> Bool {
            switch status {
            case .stopped:
                return true
            default:
                break
            }
            return false
        }

        func canMoveTo(_ next: PrimaryAcuityPlanRequestStatus) -> Bool {
            switch status {
            case .idle:
                switch next {
                case .stopped:
                    return true
                default:
                    break
                }
                return false
            case .warming:
                switch next {
                case .stopped:
                    return true
                default:
                    break
                }
                return false
            case .ready:
                return next == PrimaryAcuityPlanRequestStatus.draining || next == PrimaryAcuityPlanRequestStatus.stopped
            case .draining:
                switch next {
                case .stopped:
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

        func moveTo(_ next: PrimaryAcuityPlanRequestStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("primary acuity plan request \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
            expiresAt = Int(Date().timeIntervalSince1970)
        }

        func label() -> String {
            return "\(code): \(name)"
        }

        func projectedTotal() -> Double {
            return ((Double(endsAt) - Double(limit)) * 100).rounded() / 100
        }

        func copyValue() -> PrimaryAcuityPlanRequest {
            return PrimaryAcuityPlanRequest(
                code: code,
                name: name,
                limit: limit,
                durationMinutes: durationMinutes,
                patientRef: patientRef,
                expiresAt: expiresAt,
                active: active,
                contactEmail: contactEmail,
                visible: visible,
                endsAt: endsAt,
                priority: priority,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(name)
        }
    }

    /// Starts a primary acuity plan request in status idle.
    static func newPrimaryAcuityPlanRequest(_ code: String, name: String) -> PrimaryAcuityPlanRequest {
        return PrimaryAcuityPlanRequest(
            code: code,
            name: name,
            limit: 0,
            durationMinutes: 0,
            patientRef: "",
            expiresAt: 0,
            active: false,
            contactEmail: "",
            visible: false,
            endsAt: 0,
            priority: 0,
            status: PrimaryAcuityPlanRequestStatus.idle
        )
    }
}
