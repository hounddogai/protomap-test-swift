import AcmePlatform
import Foundation

extension CareManagement {
    /// Where a program template is in its life cycle.
    enum ProgramTemplateStatus: String, CaseIterable {
        case proposed
        case approved
        case rejected
        case withdrawn
    }

    /// A program template as the program team keeps it.
    final class ProgramTemplate {
        var code: String
        var name: String
        var patientRef: String
        var threshold: Double
        var reviewer: String
        var dosageMg: Double
        var label: String
        var quantity: Int
        var startsAt: Int
        var refills: Int
        var status: ProgramTemplateStatus

        init(code: String, name: String, patientRef: String, threshold: Double, reviewer: String, dosageMg: Double, label: String, quantity: Int, startsAt: Int, refills: Int, status: ProgramTemplateStatus) {
            self.code = code
            self.name = name
            self.patientRef = patientRef
            self.threshold = threshold
            self.reviewer = reviewer
            self.dosageMg = dosageMg
            self.label = label
            self.quantity = quantity
            self.startsAt = startsAt
            self.refills = refills
            self.status = status
        }

        /// Reports whether the record can no longer change status.
        func isTerminal() -> Bool {
            switch status {
            case .withdrawn:
                return true
            default:
                break
            }
            return false
        }

        func canMoveTo(_ next: ProgramTemplateStatus) -> Bool {
            switch status {
            case .proposed:
                return next == ProgramTemplateStatus.approved || next == ProgramTemplateStatus.rejected
            case .approved:
                return next == ProgramTemplateStatus.rejected || next == ProgramTemplateStatus.withdrawn
            case .rejected:
                return next == ProgramTemplateStatus.withdrawn
            default:
                break
            }
            return false
        }

        func moveTo(_ next: ProgramTemplateStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("program template \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
            startsAt = Int(Date().timeIntervalSince1970)
        }

        func displayLabel() -> String {
            return "\(code) / \(name)"
        }

        func adjustedLoad() -> Double {
            return ((Double(startsAt) - threshold) * 100).rounded() / 100
        }

        func copyValue() -> ProgramTemplate {
            return ProgramTemplate(
                code: code,
                name: name,
                patientRef: patientRef,
                threshold: threshold,
                reviewer: reviewer,
                dosageMg: dosageMg,
                label: label,
                quantity: quantity,
                startsAt: startsAt,
                refills: refills,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(name)
        }
    }

    /// Starts a program template in status proposed.
    static func newProgramTemplate(_ code: String, name: String) -> ProgramTemplate {
        return ProgramTemplate(
            code: code,
            name: name,
            patientRef: "",
            threshold: 0.0,
            reviewer: "",
            dosageMg: 0.0,
            label: "",
            quantity: 0,
            startsAt: 0,
            refills: 0,
            status: ProgramTemplateStatus.proposed
        )
    }
}
