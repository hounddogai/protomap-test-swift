import AcmePlatform
import Foundation

extension CareManagement {
    /// Where a pending outreach slot is in its life cycle.
    enum PendingOutreachSlotStatus: String, CaseIterable {
        case new
        case queued
        case running
        case done
        case failed
    }

    /// A pending outreach slot. Its code is unique within a tenant.
    final class PendingOutreachSlot {
        var code: String
        var name: String
        var margin: Double
        var capacity: Int
        var attributes: [String: String]
        var currency: String
        var bed: String
        var patientRef: String
        var title: String
        var status: PendingOutreachSlotStatus

        init(code: String, name: String, margin: Double, capacity: Int, attributes: [String: String], currency: String, bed: String, patientRef: String, title: String, status: PendingOutreachSlotStatus) {
            self.code = code
            self.name = name
            self.margin = margin
            self.capacity = capacity
            self.attributes = attributes
            self.currency = currency
            self.bed = bed
            self.patientRef = patientRef
            self.title = title
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

        func canMoveTo(_ next: PendingOutreachSlotStatus) -> Bool {
            switch status {
            case .new:
                switch next {
                case .failed:
                    return true
                default:
                    break
                }
                return false
            case .queued:
                return next == PendingOutreachSlotStatus.done || next == PendingOutreachSlotStatus.failed
            case .running:
                return next == PendingOutreachSlotStatus.done || next == PendingOutreachSlotStatus.failed
            case .done:
                return next == PendingOutreachSlotStatus.failed
            default:
                break
            }
            return false
        }

        func moveTo(_ next: PendingOutreachSlotStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("pending outreach slot \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
        }

        func label() -> String {
            return "\("pending outreach slot") \(code)"
        }

        func attribute(_ key: String, fallback: String) -> String {
            guard let found = attributes[key] else {
                return fallback
            }
            if found.trimmingCharacters(in: .whitespaces) == "" {
                return fallback
            }
            return found
        }

        func effectiveTotal() -> Double {
            return ((margin - Double(capacity)) * 100).rounded() / 100
        }

        func copyValue() -> PendingOutreachSlot {
            return PendingOutreachSlot(
                code: code,
                name: name,
                margin: margin,
                capacity: capacity,
                attributes: attributes,
                currency: currency,
                bed: bed,
                patientRef: patientRef,
                title: title,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(name)
        }
    }

    /// Starts a pending outreach slot in status new.
    static func newPendingOutreachSlot(_ code: String, name: String) -> PendingOutreachSlot {
        return PendingOutreachSlot(
            code: code,
            name: name,
            margin: 0.0,
            capacity: 0,
            attributes: [:],
            currency: "",
            bed: "",
            patientRef: "",
            title: "",
            status: PendingOutreachSlotStatus.new
        )
    }
}
