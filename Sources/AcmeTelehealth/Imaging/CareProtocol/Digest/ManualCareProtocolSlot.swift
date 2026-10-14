import AcmePlatform
import Foundation

extension Imaging {
    /// Where a manual care protocol slot is in its life cycle.
    enum ManualCareProtocolSlotStatus: String, CaseIterable {
        case new
        case queued
        case running
        case done
        case failed
    }

    /// One manual care protocol slot, with what the planners need to act on it.
    final class ManualCareProtocolSlot {
        var code: String
        var label: String
        var description: String
        var pinned: Bool
        var procedureCode: String
        var threshold: Double
        var score: Double
        var contactEmail: String
        var refills: Int
        var allergy: String
        var patientRef: String
        var status: ManualCareProtocolSlotStatus

        init(code: String, label: String, description: String, pinned: Bool, procedureCode: String, threshold: Double, score: Double, contactEmail: String, refills: Int, allergy: String, patientRef: String, status: ManualCareProtocolSlotStatus) {
            self.code = code
            self.label = label
            self.description = description
            self.pinned = pinned
            self.procedureCode = procedureCode
            self.threshold = threshold
            self.score = score
            self.contactEmail = contactEmail
            self.refills = refills
            self.allergy = allergy
            self.patientRef = patientRef
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

        func canMoveTo(_ next: ManualCareProtocolSlotStatus) -> Bool {
            switch status {
            case .new:
                switch next {
                case .running, .done:
                    return true
                default:
                    break
                }
                return false
            case .queued:
                switch next {
                case .running, .done:
                    return true
                default:
                    break
                }
                return false
            case .running:
                return next == ManualCareProtocolSlotStatus.done || next == ManualCareProtocolSlotStatus.failed
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

        func moveTo(_ next: ManualCareProtocolSlotStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("manual care protocol slot \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
        }

        func displayLabel() -> String {
            return "\(code): \(label)"
        }

        func netValue() -> Double {
            return (threshold * Double(refills) * 100).rounded() / 100
        }

        func copyValue() -> ManualCareProtocolSlot {
            return ManualCareProtocolSlot(
                code: code,
                label: label,
                description: description,
                pinned: pinned,
                procedureCode: procedureCode,
                threshold: threshold,
                score: score,
                contactEmail: contactEmail,
                refills: refills,
                allergy: allergy,
                patientRef: patientRef,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(label)
        }
    }

    /// Starts a manual care protocol slot in status new.
    static func newManualCareProtocolSlot(_ code: String, label: String) -> ManualCareProtocolSlot {
        return ManualCareProtocolSlot(
            code: code,
            label: label,
            description: "",
            pinned: false,
            procedureCode: "",
            threshold: 0.0,
            score: 0.0,
            contactEmail: "",
            refills: 0,
            allergy: "",
            patientRef: "",
            status: ManualCareProtocolSlotStatus.new
        )
    }
}
