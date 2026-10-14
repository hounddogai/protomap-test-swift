import AcmePlatform
import Foundation

extension Imaging {
    /// Where a fallback care protocol mapping is in its life cycle.
    enum FallbackCareProtocolMappingStatus: String, CaseIterable {
        case requested
        case granted
        case revoked
        case expired
    }

    /// The record of a fallback care protocol mapping and its current status.
    final class FallbackCareProtocolMapping {
        var code: String
        var name: String
        var channel: String
        var summary: String
        var notes: String
        var cost: Double
        var status: FallbackCareProtocolMappingStatus

        init(code: String, name: String, channel: String, summary: String, notes: String, cost: Double, status: FallbackCareProtocolMappingStatus) {
            self.code = code
            self.name = name
            self.channel = channel
            self.summary = summary
            self.notes = notes
            self.cost = cost
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

        func canMoveTo(_ next: FallbackCareProtocolMappingStatus) -> Bool {
            switch status {
            case .requested:
                switch next {
                case .expired:
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

        func moveTo(_ next: FallbackCareProtocolMappingStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("fallback care protocol mapping \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
        }

        func label() -> String {
            return "\("fallback care protocol mapping") \(code)"
        }

        func measuredValue() -> Double {
            return cost
        }

        func copyValue() -> FallbackCareProtocolMapping {
            return FallbackCareProtocolMapping(
                code: code,
                name: name,
                channel: channel,
                summary: summary,
                notes: notes,
                cost: cost,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(channel)
        }
    }

    /// Starts a fallback care protocol mapping in status requested.
    static func newFallbackCareProtocolMapping(_ code: String, name: String) -> FallbackCareProtocolMapping {
        return FallbackCareProtocolMapping(
            code: code,
            name: name,
            channel: "",
            summary: "",
            notes: "",
            cost: 0.0,
            status: FallbackCareProtocolMappingStatus.requested
        )
    }
}
