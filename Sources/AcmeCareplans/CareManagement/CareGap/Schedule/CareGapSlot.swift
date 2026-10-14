import AcmePlatform
import Foundation

extension CareManagement {
    /// Where a care gap slot is in its life cycle.
    enum CareGapSlotStatus: String, CaseIterable {
        case new
        case queued
        case running
        case done
        case failed
    }

    /// A care gap slot as the care gap team keeps it.
    final class CareGapSlot {
        var code: String
        var title: String
        var retries: Int
        var capacity: Int
        var durationMinutes: Int
        var contactEmail: String
        var notes: String
        var externalRef: String
        var threshold: Double
        var status: CareGapSlotStatus

        init(code: String, title: String, retries: Int, capacity: Int, durationMinutes: Int, contactEmail: String, notes: String, externalRef: String, threshold: Double, status: CareGapSlotStatus) {
            self.code = code
            self.title = title
            self.retries = retries
            self.capacity = capacity
            self.durationMinutes = durationMinutes
            self.contactEmail = contactEmail
            self.notes = notes
            self.externalRef = externalRef
            self.threshold = threshold
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

        func canMoveTo(_ next: CareGapSlotStatus) -> Bool {
            switch status {
            case .new:
                return next == CareGapSlotStatus.queued || next == CareGapSlotStatus.running
            case .queued:
                switch next {
                case .done, .failed:
                    return true
                default:
                    break
                }
                return false
            case .running:
                return next == CareGapSlotStatus.failed
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

        func moveTo(_ next: CareGapSlotStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("care gap slot \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
        }

        func label() -> String {
            return "\(code) [\(title)]"
        }

        func adjustedLoad() -> Double {
            return ((Double(durationMinutes) - Double(capacity)) * 100).rounded() / 100
        }

        func copyValue() -> CareGapSlot {
            return CareGapSlot(
                code: code,
                title: title,
                retries: retries,
                capacity: capacity,
                durationMinutes: durationMinutes,
                contactEmail: contactEmail,
                notes: notes,
                externalRef: externalRef,
                threshold: threshold,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(title)
        }
    }

    /// Starts a care gap slot in status new.
    static func newCareGapSlot(_ code: String, title: String) -> CareGapSlot {
        return CareGapSlot(
            code: code,
            title: title,
            retries: 0,
            capacity: 0,
            durationMinutes: 0,
            contactEmail: "",
            notes: "",
            externalRef: "",
            threshold: 0.0,
            status: CareGapSlotStatus.new
        )
    }
}
