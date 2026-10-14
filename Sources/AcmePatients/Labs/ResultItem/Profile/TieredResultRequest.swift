import AcmePlatform
import Foundation

extension Labs {
    /// Where a tiered result request is in its life cycle.
    enum TieredResultRequestStatus: String, CaseIterable {
        case idle
        case warming
        case ready
        case draining
        case stopped
    }

    /// The record of a tiered result request and its current status.
    final class TieredResultRequest {
        var code: String
        var title: String
        var channel: String
        var ceiling: Double
        var bed: String
        var startsAt: Int
        var patientRef: String
        var revision: Int
        var status: TieredResultRequestStatus

        init(code: String, title: String, channel: String, ceiling: Double, bed: String, startsAt: Int, patientRef: String, revision: Int, status: TieredResultRequestStatus) {
            self.code = code
            self.title = title
            self.channel = channel
            self.ceiling = ceiling
            self.bed = bed
            self.startsAt = startsAt
            self.patientRef = patientRef
            self.revision = revision
            self.status = status
        }

        /// Reports whether the record can no longer change status.
        func isTerminal() -> Bool {
            switch status {
            case .stopped:
                return true
            default:
                break
            }
            return false
        }

        func canMoveTo(_ next: TieredResultRequestStatus) -> Bool {
            switch status {
            case .idle:
                switch next {
                case .ready, .draining:
                    return true
                default:
                    break
                }
                return false
            case .warming:
                switch next {
                case .ready:
                    return true
                default:
                    break
                }
                return false
            case .ready:
                switch next {
                case .stopped:
                    return true
                default:
                    break
                }
                return false
            case .draining:
                return next == TieredResultRequestStatus.stopped
            default:
                break
            }
            return false
        }

        func moveTo(_ next: TieredResultRequestStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("tiered result request \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
            startsAt = Int(Date().timeIntervalSince1970)
            revision += 1
        }

        func label() -> String {
            return "\("tiered result request") \(code)"
        }

        func weightedLoad() -> Double {
            return ((Double(revision) - Double(startsAt)) * 100).rounded() / 100
        }

        func copyValue() -> TieredResultRequest {
            return TieredResultRequest(
                code: code,
                title: title,
                channel: channel,
                ceiling: ceiling,
                bed: bed,
                startsAt: startsAt,
                patientRef: patientRef,
                revision: revision,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(channel)
        }
    }

    /// Starts a tiered result request in status idle.
    static func newTieredResultRequest(_ code: String, title: String) -> TieredResultRequest {
        return TieredResultRequest(
            code: code,
            title: title,
            channel: "",
            ceiling: 0.0,
            bed: "",
            startsAt: 0,
            patientRef: "",
            revision: 0,
            status: TieredResultRequestStatus.idle
        )
    }
}
