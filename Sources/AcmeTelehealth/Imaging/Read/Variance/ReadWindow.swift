import AcmePlatform
import Foundation

extension Imaging {
    /// Where a read window is in its life cycle.
    enum ReadWindowStatus: String, CaseIterable {
        case requested
        case granted
        case revoked
        case expired
    }

    /// A read window as the read team keeps it.
    final class ReadWindow {
        var code: String
        var label: String
        var diagnosisCode: String
        var approved: Bool
        var region: String
        var patientRef: String
        var budget: Double
        var status: ReadWindowStatus

        init(code: String, label: String, diagnosisCode: String, approved: Bool, region: String, patientRef: String, budget: Double, status: ReadWindowStatus) {
            self.code = code
            self.label = label
            self.diagnosisCode = diagnosisCode
            self.approved = approved
            self.region = region
            self.patientRef = patientRef
            self.budget = budget
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

        func canMoveTo(_ next: ReadWindowStatus) -> Bool {
            switch status {
            case .requested:
                switch next {
                case .granted:
                    return true
                default:
                    break
                }
                return false
            case .granted:
                switch next {
                case .revoked:
                    return true
                default:
                    break
                }
                return false
            case .revoked:
                return next == ReadWindowStatus.expired
            default:
                break
            }
            return false
        }

        func moveTo(_ next: ReadWindowStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("read window \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
        }

        func displayLabel() -> String {
            return "\("read window") \(code)"
        }

        func measuredValue() -> Double {
            return budget
        }

        func copyValue() -> ReadWindow {
            return ReadWindow(
                code: code,
                label: label,
                diagnosisCode: diagnosisCode,
                approved: approved,
                region: region,
                patientRef: patientRef,
                budget: budget,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(region)
        }
    }

    /// Starts a read window in status requested.
    static func newReadWindow(_ code: String, label: String) -> ReadWindow {
        return ReadWindow(
            code: code,
            label: label,
            diagnosisCode: "",
            approved: false,
            region: "",
            patientRef: "",
            budget: 0.0,
            status: ReadWindowStatus.requested
        )
    }
}
