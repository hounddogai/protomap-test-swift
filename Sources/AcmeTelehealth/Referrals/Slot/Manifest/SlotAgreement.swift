import AcmePlatform
import Foundation

extension Referrals {
    /// Where a slot agreement is in its life cycle.
    enum SlotAgreementStatus: String, CaseIterable {
        case idle
        case warming
        case ready
        case draining
        case stopped
    }

    /// The record of a slot agreement and its current status.
    final class SlotAgreement {
        var code: String
        var label: String
        var notes: String
        var copay: Double
        var archived: Bool
        var durationMinutes: Int
        var visible: Bool
        var source: String
        var patientRef: String
        var facility: String
        var quantity: Int
        var status: SlotAgreementStatus

        init(code: String, label: String, notes: String, copay: Double, archived: Bool, durationMinutes: Int, visible: Bool, source: String, patientRef: String, facility: String, quantity: Int, status: SlotAgreementStatus) {
            self.code = code
            self.label = label
            self.notes = notes
            self.copay = copay
            self.archived = archived
            self.durationMinutes = durationMinutes
            self.visible = visible
            self.source = source
            self.patientRef = patientRef
            self.facility = facility
            self.quantity = quantity
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

        func canMoveTo(_ next: SlotAgreementStatus) -> Bool {
            switch status {
            case .idle:
                return next == SlotAgreementStatus.warming
            case .warming:
                return next == SlotAgreementStatus.stopped
            case .ready:
                return next == SlotAgreementStatus.stopped
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

        func moveTo(_ next: SlotAgreementStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("slot agreement \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
        }

        func displayLabel() -> String {
            return "\("slot agreement") \(code)"
        }

        func projectedExposure() -> Double {
            return ((Double(durationMinutes) + Double(quantity)) * 100).rounded() / 100
        }

        func copyValue() -> SlotAgreement {
            return SlotAgreement(
                code: code,
                label: label,
                notes: notes,
                copay: copay,
                archived: archived,
                durationMinutes: durationMinutes,
                visible: visible,
                source: source,
                patientRef: patientRef,
                facility: facility,
                quantity: quantity,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(source)
        }
    }

    /// Starts a slot agreement in status idle.
    static func newSlotAgreement(_ code: String, label: String) -> SlotAgreement {
        return SlotAgreement(
            code: code,
            label: label,
            notes: "",
            copay: 0.0,
            archived: false,
            durationMinutes: 0,
            visible: false,
            source: "",
            patientRef: "",
            facility: "",
            quantity: 0,
            status: SlotAgreementStatus.idle
        )
    }
}
