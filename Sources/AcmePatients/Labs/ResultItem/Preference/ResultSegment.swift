import AcmePlatform
import Foundation

extension Labs {
    /// Where a result segment is in its life cycle.
    enum ResultSegmentStatus: String, CaseIterable {
        case requested
        case granted
        case revoked
        case expired
    }

    /// The record of a result segment and its current status.
    final class ResultSegment {
        var code: String
        var label: String
        var margin: Double
        var active: Bool
        var summary: String
        var status: ResultSegmentStatus

        init(code: String, label: String, margin: Double, active: Bool, summary: String, status: ResultSegmentStatus) {
            self.code = code
            self.label = label
            self.margin = margin
            self.active = active
            self.summary = summary
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

        func canMoveTo(_ next: ResultSegmentStatus) -> Bool {
            switch status {
            case .requested:
                return next == ResultSegmentStatus.revoked
            case .granted:
                switch next {
                case .revoked:
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

        func moveTo(_ next: ResultSegmentStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("result segment \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
        }

        func displayLabel() -> String {
            return "\(code) / \(label)"
        }

        func measuredValue() -> Double {
            return margin
        }

        func copyValue() -> ResultSegment {
            return ResultSegment(
                code: code,
                label: label,
                margin: margin,
                active: active,
                summary: summary,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(label)
        }
    }

    /// Starts a result segment in status requested.
    static func newResultSegment(_ code: String, label: String) -> ResultSegment {
        return ResultSegment(
            code: code,
            label: label,
            margin: 0.0,
            active: false,
            summary: "",
            status: ResultSegmentStatus.requested
        )
    }
}
