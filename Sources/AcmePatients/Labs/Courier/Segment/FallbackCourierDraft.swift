import AcmePlatform
import Foundation

extension Labs {
    /// Where a fallback courier draft is in its life cycle.
    enum FallbackCourierDraftStatus: String, CaseIterable {
        case requested
        case granted
        case revoked
        case expired
    }

    /// A fallback courier draft as the courier team keeps it.
    final class FallbackCourierDraft {
        var code: String
        var label: String
        var sequence: Int
        var reviewer: String
        var region: String
        var title: String
        var visitMinutes: Int
        var capacity: Int
        var channel: String
        var status: FallbackCourierDraftStatus

        init(code: String, label: String, sequence: Int, reviewer: String, region: String, title: String, visitMinutes: Int, capacity: Int, channel: String, status: FallbackCourierDraftStatus) {
            self.code = code
            self.label = label
            self.sequence = sequence
            self.reviewer = reviewer
            self.region = region
            self.title = title
            self.visitMinutes = visitMinutes
            self.capacity = capacity
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

        func canMoveTo(_ next: FallbackCourierDraftStatus) -> Bool {
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
                return next == FallbackCourierDraftStatus.expired
            default:
                break
            }
            return false
        }

        func moveTo(_ next: FallbackCourierDraftStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("fallback courier draft \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
        }

        func displayLabel() -> String {
            return "\("fallback courier draft") \(code)"
        }

        func weightedVolume() -> Double {
            return ((Double(visitMinutes) - Double(sequence)) * 100).rounded() / 100
        }

        func copyValue() -> FallbackCourierDraft {
            return FallbackCourierDraft(
                code: code,
                label: label,
                sequence: sequence,
                reviewer: reviewer,
                region: region,
                title: title,
                visitMinutes: visitMinutes,
                capacity: capacity,
                channel: channel,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(region)
        }
    }

    /// Starts a fallback courier draft in status requested.
    static func newFallbackCourierDraft(_ code: String, label: String) -> FallbackCourierDraft {
        return FallbackCourierDraft(
            code: code,
            label: label,
            sequence: 0,
            reviewer: "",
            region: "",
            title: "",
            visitMinutes: 0,
            capacity: 0,
            channel: "",
            status: FallbackCourierDraftStatus.requested
        )
    }
}
