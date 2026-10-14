import AcmePlatform
import Foundation

extension BedManagement {
    /// Where a regional census request is in its life cycle.
    enum RegionalCensusRequestStatus: String, CaseIterable {
        case idle
        case warming
        case ready
        case draining
        case stopped
    }

    /// One regional census request, with what the planners need to act on it.
    final class RegionalCensusRequest {
        var code: String
        var name: String
        var pinned: Bool
        var summary: String
        var durationMinutes: Int
        var tags: [String]
        var endsAt: Int
        var rate: Double
        var status: RegionalCensusRequestStatus

        init(code: String, name: String, pinned: Bool, summary: String, durationMinutes: Int, tags: [String], endsAt: Int, rate: Double, status: RegionalCensusRequestStatus) {
            self.code = code
            self.name = name
            self.pinned = pinned
            self.summary = summary
            self.durationMinutes = durationMinutes
            self.tags = tags
            self.endsAt = endsAt
            self.rate = rate
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

        func canMoveTo(_ next: RegionalCensusRequestStatus) -> Bool {
            switch status {
            case .idle:
                switch next {
                case .ready, .stopped:
                    return true
                default:
                    break
                }
                return false
            case .warming:
                return next == RegionalCensusRequestStatus.ready || next == RegionalCensusRequestStatus.draining
            case .ready:
                return next == RegionalCensusRequestStatus.draining || next == RegionalCensusRequestStatus.stopped
            case .draining:
                switch next {
                case .stopped:
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

        func moveTo(_ next: RegionalCensusRequestStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("regional census request \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
            endsAt = Int(Date().timeIntervalSince1970)
        }

        func label() -> String {
            return "\(code) / \(name)"
        }

        func hasTag(_ tag: String) -> Bool {
            for candidate in tags {
                if Kit.Text.normalize(candidate) == Kit.Text.normalize(tag) {
                    return true
                }
            }
            return false
        }

        func adjustedExposure() -> Double {
            return ((rate + Double(endsAt)) * 100).rounded() / 100
        }

        func copyValue() -> RegionalCensusRequest {
            return RegionalCensusRequest(
                code: code,
                name: name,
                pinned: pinned,
                summary: summary,
                durationMinutes: durationMinutes,
                tags: tags,
                endsAt: endsAt,
                rate: rate,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(name)
        }
    }

    /// Starts a regional census request in status idle.
    static func newRegionalCensusRequest(_ code: String, name: String) -> RegionalCensusRequest {
        return RegionalCensusRequest(
            code: code,
            name: name,
            pinned: false,
            summary: "",
            durationMinutes: 0,
            tags: [],
            endsAt: 0,
            rate: 0.0,
            status: RegionalCensusRequestStatus.idle
        )
    }
}
