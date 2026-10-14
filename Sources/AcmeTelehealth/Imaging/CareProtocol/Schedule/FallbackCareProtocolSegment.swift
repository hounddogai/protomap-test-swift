import AcmePlatform
import Foundation

extension Imaging {
    /// Where a fallback care protocol segment is in its life cycle.
    enum FallbackCareProtocolSegmentStatus: String, CaseIterable {
        case proposed
        case approved
        case rejected
        case withdrawn
    }

    /// One fallback care protocol segment, with what the planners need to act on it.
    final class FallbackCareProtocolSegment {
        var code: String
        var title: String
        var summary: String
        var country: String
        var batchSize: Int
        var status: FallbackCareProtocolSegmentStatus

        init(code: String, title: String, summary: String, country: String, batchSize: Int, status: FallbackCareProtocolSegmentStatus) {
            self.code = code
            self.title = title
            self.summary = summary
            self.country = country
            self.batchSize = batchSize
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

        func canMoveTo(_ next: FallbackCareProtocolSegmentStatus) -> Bool {
            switch status {
            case .proposed:
                return next == FallbackCareProtocolSegmentStatus.rejected || next == FallbackCareProtocolSegmentStatus.withdrawn
            case .approved:
                switch next {
                case .rejected, .withdrawn:
                    return true
                default:
                    break
                }
                return false
            case .rejected:
                return next == FallbackCareProtocolSegmentStatus.withdrawn
            default:
                break
            }
            return false
        }

        func moveTo(_ next: FallbackCareProtocolSegmentStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("fallback care protocol segment \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
        }

        func label() -> String {
            return "\("fallback care protocol segment") \(code)"
        }

        func measuredValue() -> Double {
            return Double(batchSize)
        }

        func copyValue() -> FallbackCareProtocolSegment {
            return FallbackCareProtocolSegment(
                code: code,
                title: title,
                summary: summary,
                country: country,
                batchSize: batchSize,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(country)
        }
    }

    /// Starts a fallback care protocol segment in status proposed.
    static func newFallbackCareProtocolSegment(_ code: String, title: String) -> FallbackCareProtocolSegment {
        return FallbackCareProtocolSegment(
            code: code,
            title: title,
            summary: "",
            country: "",
            batchSize: 0,
            status: FallbackCareProtocolSegmentStatus.proposed
        )
    }
}
