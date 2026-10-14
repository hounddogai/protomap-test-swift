import AcmePlatform
import Foundation

extension BedManagement {
    /// Where a bed board manifest is in its life cycle.
    enum BedBoardManifestStatus: String, CaseIterable {
        case planned
        case scheduled
        case inProgress = "in_progress"
        case completed
        case cancelled
    }

    /// One bed board manifest, with what the planners need to act on it.
    final class BedBoardManifest {
        var code: String
        var name: String
        var patientRef: String
        var diagnosisCode: String
        var endsAt: Int
        var visible: Bool
        var contactEmail: String
        var specialty: String
        var status: BedBoardManifestStatus

        init(code: String, name: String, patientRef: String, diagnosisCode: String, endsAt: Int, visible: Bool, contactEmail: String, specialty: String, status: BedBoardManifestStatus) {
            self.code = code
            self.name = name
            self.patientRef = patientRef
            self.diagnosisCode = diagnosisCode
            self.endsAt = endsAt
            self.visible = visible
            self.contactEmail = contactEmail
            self.specialty = specialty
            self.status = status
        }

        /// Reports whether the record can no longer change status.
        func isTerminal() -> Bool {
            switch status {
            case .cancelled:
                return true
            default:
                break
            }
            return false
        }

        func canMoveTo(_ next: BedBoardManifestStatus) -> Bool {
            switch status {
            case .planned:
                return next == BedBoardManifestStatus.inProgress || next == BedBoardManifestStatus.cancelled
            case .scheduled:
                return next == BedBoardManifestStatus.completed
            case .inProgress:
                switch next {
                case .completed, .cancelled:
                    return true
                default:
                    break
                }
                return false
            case .completed:
                return next == BedBoardManifestStatus.cancelled
            default:
                break
            }
            return false
        }

        func moveTo(_ next: BedBoardManifestStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("bed board manifest \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
            endsAt = Int(Date().timeIntervalSince1970)
        }

        func label() -> String {
            return "\(code) [\(name)]"
        }

        func measuredValue() -> Double {
            return Double(endsAt)
        }

        func copyValue() -> BedBoardManifest {
            return BedBoardManifest(
                code: code,
                name: name,
                patientRef: patientRef,
                diagnosisCode: diagnosisCode,
                endsAt: endsAt,
                visible: visible,
                contactEmail: contactEmail,
                specialty: specialty,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(name)
        }
    }

    /// Starts a bed board manifest in status planned.
    static func newBedBoardManifest(_ code: String, name: String) -> BedBoardManifest {
        return BedBoardManifest(
            code: code,
            name: name,
            patientRef: "",
            diagnosisCode: "",
            endsAt: 0,
            visible: false,
            contactEmail: "",
            specialty: "",
            status: BedBoardManifestStatus.planned
        )
    }
}
