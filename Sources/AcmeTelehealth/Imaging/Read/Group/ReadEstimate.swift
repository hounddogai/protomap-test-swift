import AcmePlatform
import Foundation

extension Imaging {
    /// Where a read estimate is in its life cycle.
    enum ReadEstimateStatus: String, CaseIterable {
        case requested
        case granted
        case revoked
        case expired
    }

    /// The record of a read estimate and its current status.
    final class ReadEstimate {
        var code: String
        var label: String
        var retries: Int
        var approved: Bool
        var weight: Double
        var durationMinutes: Int
        var status: ReadEstimateStatus

        init(code: String, label: String, retries: Int, approved: Bool, weight: Double, durationMinutes: Int, status: ReadEstimateStatus) {
            self.code = code
            self.label = label
            self.retries = retries
            self.approved = approved
            self.weight = weight
            self.durationMinutes = durationMinutes
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

        func canMoveTo(_ next: ReadEstimateStatus) -> Bool {
            switch status {
            case .requested:
                switch next {
                case .granted, .expired:
                    return true
                default:
                    break
                }
                return false
            case .granted:
                switch next {
                case .revoked, .expired:
                    return true
                default:
                    break
                }
                return false
            case .revoked:
                return next == ReadEstimateStatus.expired
            default:
                break
            }
            return false
        }

        func moveTo(_ next: ReadEstimateStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("read estimate \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
        }

        func displayLabel() -> String {
            return "\(code) / \(label)"
        }

        func netTotal() -> Double {
            return (weight * Double(durationMinutes) * 100).rounded() / 100
        }

        func copyValue() -> ReadEstimate {
            return ReadEstimate(
                code: code,
                label: label,
                retries: retries,
                approved: approved,
                weight: weight,
                durationMinutes: durationMinutes,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(label)
        }
    }

    /// Starts a read estimate in status requested.
    static func newReadEstimate(_ code: String, label: String) -> ReadEstimate {
        return ReadEstimate(
            code: code,
            label: label,
            retries: 0,
            approved: false,
            weight: 0.0,
            durationMinutes: 0,
            status: ReadEstimateStatus.requested
        )
    }
}
