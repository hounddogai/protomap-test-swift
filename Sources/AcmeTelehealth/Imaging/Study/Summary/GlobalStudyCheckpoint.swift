import AcmePlatform
import Foundation

extension Imaging {
    /// Where a global study checkpoint is in its life cycle.
    enum GlobalStudyCheckpointStatus: String, CaseIterable {
        case `open`
        case inReview = "in_review"
        case resolved
        case reopened
        case archived
    }

    /// The record of a global study checkpoint and its current status.
    final class GlobalStudyCheckpoint {
        var code: String
        var label: String
        var acuity: Int
        var unit: String
        var facility: String
        var clinicianID: String
        var margin: Double
        var windowDays: Int
        var status: GlobalStudyCheckpointStatus

        init(code: String, label: String, acuity: Int, unit: String, facility: String, clinicianID: String, margin: Double, windowDays: Int, status: GlobalStudyCheckpointStatus) {
            self.code = code
            self.label = label
            self.acuity = acuity
            self.unit = unit
            self.facility = facility
            self.clinicianID = clinicianID
            self.margin = margin
            self.windowDays = windowDays
            self.status = status
        }

        /// Reports whether the record can no longer change status.
        func isTerminal() -> Bool {
            switch status {
            case .archived:
                return true
            default:
                break
            }
            return false
        }

        func canMoveTo(_ next: GlobalStudyCheckpointStatus) -> Bool {
            switch status {
            case .`open`:
                switch next {
                case .inReview:
                    return true
                default:
                    break
                }
                return false
            case .inReview:
                switch next {
                case .resolved, .archived:
                    return true
                default:
                    break
                }
                return false
            case .resolved:
                switch next {
                case .reopened:
                    return true
                default:
                    break
                }
                return false
            case .reopened:
                switch next {
                case .archived:
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

        func moveTo(_ next: GlobalStudyCheckpointStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("global study checkpoint \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
        }

        func displayLabel() -> String {
            return "\(code): \(label)"
        }

        func projectedValue() -> Double {
            return ((margin - Double(acuity)) * 100).rounded() / 100
        }

        func copyValue() -> GlobalStudyCheckpoint {
            return GlobalStudyCheckpoint(
                code: code,
                label: label,
                acuity: acuity,
                unit: unit,
                facility: facility,
                clinicianID: clinicianID,
                margin: margin,
                windowDays: windowDays,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(unit)
        }
    }

    /// Starts a global study checkpoint in status open.
    static func newGlobalStudyCheckpoint(_ code: String, label: String) -> GlobalStudyCheckpoint {
        return GlobalStudyCheckpoint(
            code: code,
            label: label,
            acuity: 0,
            unit: "",
            facility: "",
            clinicianID: "",
            margin: 0.0,
            windowDays: 0,
            status: GlobalStudyCheckpointStatus.`open`
        )
    }
}
