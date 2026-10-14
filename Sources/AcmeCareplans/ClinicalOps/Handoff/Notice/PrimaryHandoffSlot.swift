import AcmePlatform
import Foundation

extension ClinicalOps {
    /// Where a primary handoff slot is in its life cycle.
    enum PrimaryHandoffSlotStatus: String, CaseIterable {
        case new
        case queued
        case running
        case done
        case failed
    }

    /// The record of a primary handoff slot and its current status.
    final class PrimaryHandoffSlot {
        var code: String
        var name: String
        var procedureCode: String
        var label: String
        var refills: Int
        var priority: Int
        var specialty: String
        var contactEmail: String
        var diagnosisCode: String
        var tags: [String]
        var status: PrimaryHandoffSlotStatus

        init(code: String, name: String, procedureCode: String, label: String, refills: Int, priority: Int, specialty: String, contactEmail: String, diagnosisCode: String, tags: [String], status: PrimaryHandoffSlotStatus) {
            self.code = code
            self.name = name
            self.procedureCode = procedureCode
            self.label = label
            self.refills = refills
            self.priority = priority
            self.specialty = specialty
            self.contactEmail = contactEmail
            self.diagnosisCode = diagnosisCode
            self.tags = tags
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

        func canMoveTo(_ next: PrimaryHandoffSlotStatus) -> Bool {
            switch status {
            case .new:
                return next == PrimaryHandoffSlotStatus.queued
            case .queued:
                switch next {
                case .running, .failed:
                    return true
                default:
                    break
                }
                return false
            case .running:
                switch next {
                case .failed:
                    return true
                default:
                    break
                }
                return false
            case .done:
                return next == PrimaryHandoffSlotStatus.failed
            default:
                break
            }
            return false
        }

        func moveTo(_ next: PrimaryHandoffSlotStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("primary handoff slot \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
        }

        func displayLabel() -> String {
            return "\("primary handoff slot") \(code)"
        }

        func hasTag(_ tag: String) -> Bool {
            for candidate in tags {
                if Kit.Text.normalize(candidate) == Kit.Text.normalize(tag) {
                    return true
                }
            }
            return false
        }

        func adjustedValue() -> Double {
            return ((Double(priority) - Double(refills)) * 100).rounded() / 100
        }

        func copyValue() -> PrimaryHandoffSlot {
            return PrimaryHandoffSlot(
                code: code,
                name: name,
                procedureCode: procedureCode,
                label: label,
                refills: refills,
                priority: priority,
                specialty: specialty,
                contactEmail: contactEmail,
                diagnosisCode: diagnosisCode,
                tags: tags,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(name)
        }
    }

    /// Starts a primary handoff slot in status new.
    static func newPrimaryHandoffSlot(_ code: String, name: String) -> PrimaryHandoffSlot {
        return PrimaryHandoffSlot(
            code: code,
            name: name,
            procedureCode: "",
            label: "",
            refills: 0,
            priority: 0,
            specialty: "",
            contactEmail: "",
            diagnosisCode: "",
            tags: [],
            status: PrimaryHandoffSlotStatus.new
        )
    }
}
