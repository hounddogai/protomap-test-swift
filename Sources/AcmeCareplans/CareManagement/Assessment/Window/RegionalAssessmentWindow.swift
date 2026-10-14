import AcmePlatform
import Foundation

extension CareManagement {
    /// Where a regional assessment window is in its life cycle.
    enum RegionalAssessmentWindowStatus: String, CaseIterable {
        case idle
        case warming
        case ready
        case draining
        case stopped
    }

    /// The record of a regional assessment window and its current status.
    final class RegionalAssessmentWindow {
        var code: String
        var name: String
        var expiresAt: Int
        var copay: Double
        var updatedAt: Int
        var phone: String
        var threshold: Double
        var specialty: String
        var attempts: Int
        var contactEmail: String
        var diagnosisCode: String
        var status: RegionalAssessmentWindowStatus

        init(code: String, name: String, expiresAt: Int, copay: Double, updatedAt: Int, phone: String, threshold: Double, specialty: String, attempts: Int, contactEmail: String, diagnosisCode: String, status: RegionalAssessmentWindowStatus) {
            self.code = code
            self.name = name
            self.expiresAt = expiresAt
            self.copay = copay
            self.updatedAt = updatedAt
            self.phone = phone
            self.threshold = threshold
            self.specialty = specialty
            self.attempts = attempts
            self.contactEmail = contactEmail
            self.diagnosisCode = diagnosisCode
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

        func canMoveTo(_ next: RegionalAssessmentWindowStatus) -> Bool {
            switch status {
            case .idle:
                switch next {
                case .draining:
                    return true
                default:
                    break
                }
                return false
            case .warming:
                switch next {
                case .ready, .stopped:
                    return true
                default:
                    break
                }
                return false
            case .ready:
                switch next {
                case .draining:
                    return true
                default:
                    break
                }
                return false
            case .draining:
                return next == RegionalAssessmentWindowStatus.stopped
            default:
                break
            }
            return false
        }

        func moveTo(_ next: RegionalAssessmentWindowStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("regional assessment window \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
            expiresAt = Int(Date().timeIntervalSince1970)
        }

        func label() -> String {
            return "\("regional assessment window") \(code)"
        }

        func projectedLoad() -> Double {
            return ((copay + Double(attempts)) * 100).rounded() / 100
        }

        func copyValue() -> RegionalAssessmentWindow {
            return RegionalAssessmentWindow(
                code: code,
                name: name,
                expiresAt: expiresAt,
                copay: copay,
                updatedAt: updatedAt,
                phone: phone,
                threshold: threshold,
                specialty: specialty,
                attempts: attempts,
                contactEmail: contactEmail,
                diagnosisCode: diagnosisCode,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(name)
        }
    }

    /// Starts a regional assessment window in status idle.
    static func newRegionalAssessmentWindow(_ code: String, name: String) -> RegionalAssessmentWindow {
        return RegionalAssessmentWindow(
            code: code,
            name: name,
            expiresAt: 0,
            copay: 0.0,
            updatedAt: 0,
            phone: "",
            threshold: 0.0,
            specialty: "",
            attempts: 0,
            contactEmail: "",
            diagnosisCode: "",
            status: RegionalAssessmentWindowStatus.idle
        )
    }
}
