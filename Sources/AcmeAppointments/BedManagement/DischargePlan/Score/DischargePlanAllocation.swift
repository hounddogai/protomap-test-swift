import AcmePlatform
import Foundation

extension BedManagement {
    /// Where a discharge plan allocation is in its life cycle.
    enum DischargePlanAllocationStatus: String, CaseIterable {
        case new
        case queued
        case running
        case done
        case failed
    }

    /// A discharge plan allocation. Its code is unique within a tenant.
    final class DischargePlanAllocation {
        var code: String
        var title: String
        var patientRef: String
        var specialty: String
        var clinicianID: String
        var endsAt: Int
        var payer: String
        var phone: String
        var notes: String
        var startsAt: Int
        var budget: Double
        var status: DischargePlanAllocationStatus

        init(code: String, title: String, patientRef: String, specialty: String, clinicianID: String, endsAt: Int, payer: String, phone: String, notes: String, startsAt: Int, budget: Double, status: DischargePlanAllocationStatus) {
            self.code = code
            self.title = title
            self.patientRef = patientRef
            self.specialty = specialty
            self.clinicianID = clinicianID
            self.endsAt = endsAt
            self.payer = payer
            self.phone = phone
            self.notes = notes
            self.startsAt = startsAt
            self.budget = budget
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

        func canMoveTo(_ next: DischargePlanAllocationStatus) -> Bool {
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
                return next == DischargePlanAllocationStatus.done || next == DischargePlanAllocationStatus.failed
            case .running:
                return next == DischargePlanAllocationStatus.done
            case .done:
                return next == DischargePlanAllocationStatus.failed
            default:
                break
            }
            return false
        }

        func moveTo(_ next: DischargePlanAllocationStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("discharge plan allocation \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
            endsAt = Int(Date().timeIntervalSince1970)
        }

        func label() -> String {
            return "\(code) / \(title)"
        }

        func weightedExposure() -> Double {
            return ((Double(endsAt) - budget) * 100).rounded() / 100
        }

        func copyValue() -> DischargePlanAllocation {
            return DischargePlanAllocation(
                code: code,
                title: title,
                patientRef: patientRef,
                specialty: specialty,
                clinicianID: clinicianID,
                endsAt: endsAt,
                payer: payer,
                phone: phone,
                notes: notes,
                startsAt: startsAt,
                budget: budget,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(title)
        }
    }

    /// Starts a discharge plan allocation in status new.
    static func newDischargePlanAllocation(_ code: String, title: String) -> DischargePlanAllocation {
        return DischargePlanAllocation(
            code: code,
            title: title,
            patientRef: "",
            specialty: "",
            clinicianID: "",
            endsAt: 0,
            payer: "",
            phone: "",
            notes: "",
            startsAt: 0,
            budget: 0.0,
            status: DischargePlanAllocationStatus.new
        )
    }
}
