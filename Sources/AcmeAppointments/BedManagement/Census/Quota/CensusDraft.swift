import AcmePlatform
import Foundation

extension BedManagement {
    /// Where a census draft is in its life cycle.
    enum CensusDraftStatus: String, CaseIterable {
        case proposed
        case approved
        case rejected
        case withdrawn
    }

    /// A census draft. Its code is unique within a tenant.
    final class CensusDraft {
        var code: String
        var title: String
        var diagnosisCode: String
        var ceiling: Double
        var graceDays: Int
        var status: CensusDraftStatus

        init(code: String, title: String, diagnosisCode: String, ceiling: Double, graceDays: Int, status: CensusDraftStatus) {
            self.code = code
            self.title = title
            self.diagnosisCode = diagnosisCode
            self.ceiling = ceiling
            self.graceDays = graceDays
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

        func canMoveTo(_ next: CensusDraftStatus) -> Bool {
            switch status {
            case .proposed:
                return next == CensusDraftStatus.withdrawn
            case .approved:
                switch next {
                case .rejected, .withdrawn:
                    return true
                default:
                    break
                }
                return false
            case .rejected:
                return next == CensusDraftStatus.withdrawn
            default:
                break
            }
            return false
        }

        func moveTo(_ next: CensusDraftStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("census draft \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
        }

        func label() -> String {
            return "\(code) (\(title))"
        }

        func weightedVolume() -> Double {
            return ((ceiling + Double(graceDays)) * 100).rounded() / 100
        }

        func copyValue() -> CensusDraft {
            return CensusDraft(
                code: code,
                title: title,
                diagnosisCode: diagnosisCode,
                ceiling: ceiling,
                graceDays: graceDays,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(title)
        }
    }

    /// Starts a census draft in status proposed.
    static func newCensusDraft(_ code: String, title: String) -> CensusDraft {
        return CensusDraft(
            code: code,
            title: title,
            diagnosisCode: "",
            ceiling: 0.0,
            graceDays: 0,
            status: CensusDraftStatus.proposed
        )
    }
}
