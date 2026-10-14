import AcmePlatform
import Foundation

extension Consent {
    /// Where a lenient consent form batch is in its life cycle.
    enum LenientConsentFormBatchStatus: String, CaseIterable {
        case new
        case queued
        case running
        case done
        case failed
    }

    /// One lenient consent form batch, with what the planners need to act on it.
    final class LenientConsentFormBatch {
        var code: String
        var title: String
        var procedureCode: String
        var notes: String
        var capacity: Int
        var attempts: Int
        var unit: String
        var contactEmail: String
        var status: LenientConsentFormBatchStatus

        init(code: String, title: String, procedureCode: String, notes: String, capacity: Int, attempts: Int, unit: String, contactEmail: String, status: LenientConsentFormBatchStatus) {
            self.code = code
            self.title = title
            self.procedureCode = procedureCode
            self.notes = notes
            self.capacity = capacity
            self.attempts = attempts
            self.unit = unit
            self.contactEmail = contactEmail
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

        func canMoveTo(_ next: LenientConsentFormBatchStatus) -> Bool {
            switch status {
            case .new:
                switch next {
                case .done, .failed:
                    return true
                default:
                    break
                }
                return false
            case .queued:
                switch next {
                case .done, .failed:
                    return true
                default:
                    break
                }
                return false
            case .running:
                switch next {
                case .done, .failed:
                    return true
                default:
                    break
                }
                return false
            case .done:
                return next == LenientConsentFormBatchStatus.failed
            default:
                break
            }
            return false
        }

        func moveTo(_ next: LenientConsentFormBatchStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("lenient consent form batch \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
        }

        func label() -> String {
            return "\(code): \(title)"
        }

        func projectedExposure() -> Double {
            return ((Double(capacity) - Double(attempts)) * 100).rounded() / 100
        }

        func copyValue() -> LenientConsentFormBatch {
            return LenientConsentFormBatch(
                code: code,
                title: title,
                procedureCode: procedureCode,
                notes: notes,
                capacity: capacity,
                attempts: attempts,
                unit: unit,
                contactEmail: contactEmail,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(unit)
        }
    }

    /// Starts a lenient consent form batch in status new.
    static func newLenientConsentFormBatch(_ code: String, title: String) -> LenientConsentFormBatch {
        return LenientConsentFormBatch(
            code: code,
            title: title,
            procedureCode: "",
            notes: "",
            capacity: 0,
            attempts: 0,
            unit: "",
            contactEmail: "",
            status: LenientConsentFormBatchStatus.new
        )
    }
}
