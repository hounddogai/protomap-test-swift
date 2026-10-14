import AcmePlatform
import Foundation

extension Consent {
    /// Where a consent form quota is in its life cycle.
    enum ConsentFormQuotaStatus: String, CaseIterable {
        case idle
        case warming
        case ready
        case draining
        case stopped
    }

    /// The record of a consent form quota and its current status.
    final class ConsentFormQuota {
        var code: String
        var title: String
        var version: Int
        var refills: Int
        var weight: Double
        var category: String
        var durationMinutes: Int
        var patientRef: String
        var attempts: Int
        var status: ConsentFormQuotaStatus

        init(code: String, title: String, version: Int, refills: Int, weight: Double, category: String, durationMinutes: Int, patientRef: String, attempts: Int, status: ConsentFormQuotaStatus) {
            self.code = code
            self.title = title
            self.version = version
            self.refills = refills
            self.weight = weight
            self.category = category
            self.durationMinutes = durationMinutes
            self.patientRef = patientRef
            self.attempts = attempts
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

        func canMoveTo(_ next: ConsentFormQuotaStatus) -> Bool {
            switch status {
            case .idle:
                switch next {
                case .warming, .draining:
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
                return next == ConsentFormQuotaStatus.draining || next == ConsentFormQuotaStatus.stopped
            case .draining:
                return next == ConsentFormQuotaStatus.stopped
            default:
                break
            }
            return false
        }

        func moveTo(_ next: ConsentFormQuotaStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("consent form quota \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
            version += 1
        }

        func label() -> String {
            return "\(code) / \(title)"
        }

        func adjustedValue() -> Double {
            return ((Double(version) - Double(durationMinutes)) * 100).rounded() / 100
        }

        func copyValue() -> ConsentFormQuota {
            return ConsentFormQuota(
                code: code,
                title: title,
                version: version,
                refills: refills,
                weight: weight,
                category: category,
                durationMinutes: durationMinutes,
                patientRef: patientRef,
                attempts: attempts,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(category)
        }
    }

    /// Starts a consent form quota in status idle.
    static func newConsentFormQuota(_ code: String, title: String) -> ConsentFormQuota {
        return ConsentFormQuota(
            code: code,
            title: title,
            version: 0,
            refills: 0,
            weight: 0.0,
            category: "",
            durationMinutes: 0,
            patientRef: "",
            attempts: 0,
            status: ConsentFormQuotaStatus.idle
        )
    }
}
