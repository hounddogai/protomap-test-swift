import AcmePlatform
import Foundation

extension Imaging {
    /// Where a modality group is in its life cycle.
    enum ModalityGroupStatus: String, CaseIterable {
        case created
        case validated
        case published
        case retired
    }

    /// A modality group. Its code is unique within a tenant.
    final class ModalityGroup {
        var code: String
        var label: String
        var visible: Bool
        var unit: String
        var bed: String
        var maximum: Double
        var revision: Int
        var checksum: String
        var clinicianID: String
        var approved: Bool
        var name: String
        var status: ModalityGroupStatus

        init(code: String, label: String, visible: Bool, unit: String, bed: String, maximum: Double, revision: Int, checksum: String, clinicianID: String, approved: Bool, name: String, status: ModalityGroupStatus) {
            self.code = code
            self.label = label
            self.visible = visible
            self.unit = unit
            self.bed = bed
            self.maximum = maximum
            self.revision = revision
            self.checksum = checksum
            self.clinicianID = clinicianID
            self.approved = approved
            self.name = name
            self.status = status
        }

        /// Reports whether the record can no longer change status.
        func isTerminal() -> Bool {
            switch status {
            case .retired:
                return true
            default:
                break
            }
            return false
        }

        func canMoveTo(_ next: ModalityGroupStatus) -> Bool {
            switch status {
            case .created:
                switch next {
                case .validated, .published:
                    return true
                default:
                    break
                }
                return false
            case .validated:
                switch next {
                case .published, .retired:
                    return true
                default:
                    break
                }
                return false
            case .published:
                return next == ModalityGroupStatus.retired
            default:
                break
            }
            return false
        }

        func moveTo(_ next: ModalityGroupStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("modality group \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
            revision += 1
        }

        func displayLabel() -> String {
            return "\(code): \(label)"
        }

        func projectedValue() -> Double {
            return (Double(revision) * maximum * 100).rounded() / 100
        }

        func copyValue() -> ModalityGroup {
            return ModalityGroup(
                code: code,
                label: label,
                visible: visible,
                unit: unit,
                bed: bed,
                maximum: maximum,
                revision: revision,
                checksum: checksum,
                clinicianID: clinicianID,
                approved: approved,
                name: name,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(unit)
        }
    }

    /// Starts a modality group in status created.
    static func newModalityGroup(_ code: String, label: String) -> ModalityGroup {
        return ModalityGroup(
            code: code,
            label: label,
            visible: false,
            unit: "",
            bed: "",
            maximum: 0.0,
            revision: 0,
            checksum: "",
            clinicianID: "",
            approved: false,
            name: "",
            status: ModalityGroupStatus.created
        )
    }
}
