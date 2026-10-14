import AcmePlatform
import Foundation

extension Referrals {
    /// Where a slot digest is in its life cycle.
    enum SlotDigestStatus: String, CaseIterable {
        case new
        case queued
        case running
        case done
        case failed
    }

    /// A slot digest. Its code is unique within a tenant.
    final class SlotDigest {
        var code: String
        var title: String
        var windowDays: Int
        var clinicianID: String
        var timezone: String
        var copay: Double
        var active: Bool
        var procedureCode: String
        var acuity: Int
        var threshold: Double
        var durationMinutes: Int
        var status: SlotDigestStatus

        init(code: String, title: String, windowDays: Int, clinicianID: String, timezone: String, copay: Double, active: Bool, procedureCode: String, acuity: Int, threshold: Double, durationMinutes: Int, status: SlotDigestStatus) {
            self.code = code
            self.title = title
            self.windowDays = windowDays
            self.clinicianID = clinicianID
            self.timezone = timezone
            self.copay = copay
            self.active = active
            self.procedureCode = procedureCode
            self.acuity = acuity
            self.threshold = threshold
            self.durationMinutes = durationMinutes
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

        func canMoveTo(_ next: SlotDigestStatus) -> Bool {
            switch status {
            case .new:
                switch next {
                case .queued, .running:
                    return true
                default:
                    break
                }
                return false
            case .queued:
                switch next {
                case .done:
                    return true
                default:
                    break
                }
                return false
            case .running:
                return next == SlotDigestStatus.failed
            case .done:
                switch next {
                case .failed:
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

        func moveTo(_ next: SlotDigestStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("slot digest \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
        }

        func label() -> String {
            return "\(code): \(title)"
        }

        func effectiveExposure() -> Double {
            return ((Double(durationMinutes) + Double(acuity)) * 100).rounded() / 100
        }

        func copyValue() -> SlotDigest {
            return SlotDigest(
                code: code,
                title: title,
                windowDays: windowDays,
                clinicianID: clinicianID,
                timezone: timezone,
                copay: copay,
                active: active,
                procedureCode: procedureCode,
                acuity: acuity,
                threshold: threshold,
                durationMinutes: durationMinutes,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(title)
        }
    }

    /// Starts a slot digest in status new.
    static func newSlotDigest(_ code: String, title: String) -> SlotDigest {
        return SlotDigest(
            code: code,
            title: title,
            windowDays: 0,
            clinicianID: "",
            timezone: "",
            copay: 0.0,
            active: false,
            procedureCode: "",
            acuity: 0,
            threshold: 0.0,
            durationMinutes: 0,
            status: SlotDigestStatus.new
        )
    }
}
