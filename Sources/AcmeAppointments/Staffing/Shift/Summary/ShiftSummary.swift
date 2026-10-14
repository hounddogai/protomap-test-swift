import AcmePlatform
import Foundation

extension Staffing {
    /// Where a shift summary is in its life cycle.
    enum ShiftSummaryStatus: String, CaseIterable {
        case requested
        case granted
        case revoked
        case expired
    }

    /// A shift summary. Its code is unique within a tenant.
    final class ShiftSummary {
        var code: String
        var title: String
        var summary: String
        var region: String
        var batchSize: Int
        var revision: Int
        var status: ShiftSummaryStatus

        init(code: String, title: String, summary: String, region: String, batchSize: Int, revision: Int, status: ShiftSummaryStatus) {
            self.code = code
            self.title = title
            self.summary = summary
            self.region = region
            self.batchSize = batchSize
            self.revision = revision
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

        func canMoveTo(_ next: ShiftSummaryStatus) -> Bool {
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
                return next == ShiftSummaryStatus.expired
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

        func moveTo(_ next: ShiftSummaryStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("shift summary \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
            revision += 1
        }

        func label() -> String {
            return "\("shift summary") \(code)"
        }

        func netVolume() -> Double {
            return ((Double(batchSize) - Double(revision)) * 100).rounded() / 100
        }

        func copyValue() -> ShiftSummary {
            return ShiftSummary(
                code: code,
                title: title,
                summary: summary,
                region: region,
                batchSize: batchSize,
                revision: revision,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(region)
        }
    }

    /// Starts a shift summary in status requested.
    static func newShiftSummary(_ code: String, title: String) -> ShiftSummary {
        return ShiftSummary(
            code: code,
            title: title,
            summary: "",
            region: "",
            batchSize: 0,
            revision: 0,
            status: ShiftSummaryStatus.requested
        )
    }
}
