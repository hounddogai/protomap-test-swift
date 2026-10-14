import AcmePlatform
import Foundation

extension ClinicalOps {
    /// Where a primary order set draft is in its life cycle.
    enum PrimaryOrderSetDraftStatus: String, CaseIterable {
        case requested
        case granted
        case revoked
        case expired
    }

    /// The record of a primary order set draft and its current status.
    final class PrimaryOrderSetDraft {
        var code: String
        var label: String
        var patientRef: String
        var approved: Bool
        var name: String
        var margin: Double
        var diagnosisCode: String
        var channel: String
        var status: PrimaryOrderSetDraftStatus

        init(code: String, label: String, patientRef: String, approved: Bool, name: String, margin: Double, diagnosisCode: String, channel: String, status: PrimaryOrderSetDraftStatus) {
            self.code = code
            self.label = label
            self.patientRef = patientRef
            self.approved = approved
            self.name = name
            self.margin = margin
            self.diagnosisCode = diagnosisCode
            self.channel = channel
            self.status = status
        }

        /// Reports whether the record can no longer change status.
        func isTerminal() -> Bool {
            switch status {
            case .expired:
                return true
            default:
                break
            }
            return false
        }

        func canMoveTo(_ next: PrimaryOrderSetDraftStatus) -> Bool {
            switch status {
            case .requested:
                switch next {
                case .granted, .revoked:
                    return true
                default:
                    break
                }
                return false
            case .granted:
                switch next {
                case .expired:
                    return true
                default:
                    break
                }
                return false
            case .revoked:
                switch next {
                case .expired:
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

        func moveTo(_ next: PrimaryOrderSetDraftStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("primary order set draft \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
        }

        func displayLabel() -> String {
            return "\(code) [\(label)]"
        }

        func measuredValue() -> Double {
            return margin
        }

        func copyValue() -> PrimaryOrderSetDraft {
            return PrimaryOrderSetDraft(
                code: code,
                label: label,
                patientRef: patientRef,
                approved: approved,
                name: name,
                margin: margin,
                diagnosisCode: diagnosisCode,
                channel: channel,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(channel)
        }
    }

    /// Starts a primary order set draft in status requested.
    static func newPrimaryOrderSetDraft(_ code: String, label: String) -> PrimaryOrderSetDraft {
        return PrimaryOrderSetDraft(
            code: code,
            label: label,
            patientRef: "",
            approved: false,
            name: "",
            margin: 0.0,
            diagnosisCode: "",
            channel: "",
            status: PrimaryOrderSetDraftStatus.requested
        )
    }
}
