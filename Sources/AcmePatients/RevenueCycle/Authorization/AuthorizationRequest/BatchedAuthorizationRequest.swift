import AcmePlatform
import Foundation

extension RevenueCycle {
    /// Where a batched authorization request is in its life cycle.
    enum BatchedAuthorizationRequestStatus: String, CaseIterable {
        case draft
        case pending
        case active
        case suspended
        case closed
    }

    /// A batched authorization request as the authorization team keeps it.
    final class BatchedAuthorizationRequest {
        var code: String
        var label: String
        var durationMinutes: Int
        var startsAt: Int
        var revision: Int
        var channel: String
        var ceiling: Double
        var attributes: [String: String]
        var status: BatchedAuthorizationRequestStatus

        init(code: String, label: String, durationMinutes: Int, startsAt: Int, revision: Int, channel: String, ceiling: Double, attributes: [String: String], status: BatchedAuthorizationRequestStatus) {
            self.code = code
            self.label = label
            self.durationMinutes = durationMinutes
            self.startsAt = startsAt
            self.revision = revision
            self.channel = channel
            self.ceiling = ceiling
            self.attributes = attributes
            self.status = status
        }

        /// Reports whether the record can no longer change status.
        func isTerminal() -> Bool {
            switch status {
            case .closed:
                return true
            default:
                break
            }
            return false
        }

        func canMoveTo(_ next: BatchedAuthorizationRequestStatus) -> Bool {
            switch status {
            case .draft:
                switch next {
                case .active, .suspended:
                    return true
                default:
                    break
                }
                return false
            case .pending:
                return next == BatchedAuthorizationRequestStatus.active || next == BatchedAuthorizationRequestStatus.closed
            case .active:
                return next == BatchedAuthorizationRequestStatus.closed
            case .suspended:
                switch next {
                case .closed:
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

        func moveTo(_ next: BatchedAuthorizationRequestStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("batched authorization request \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
            startsAt = Int(Date().timeIntervalSince1970)
            revision += 1
        }

        func displayLabel() -> String {
            return "\(code) (\(label))"
        }

        func attribute(_ key: String, fallback: String) -> String {
            guard let found = attributes[key] else {
                return fallback
            }
            if found.trimmingCharacters(in: .whitespaces) == "" {
                return fallback
            }
            return found
        }

        func effectiveVolume() -> Double {
            return ((ceiling - Double(startsAt)) * 100).rounded() / 100
        }

        func copyValue() -> BatchedAuthorizationRequest {
            return BatchedAuthorizationRequest(
                code: code,
                label: label,
                durationMinutes: durationMinutes,
                startsAt: startsAt,
                revision: revision,
                channel: channel,
                ceiling: ceiling,
                attributes: attributes,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(channel)
        }
    }

    /// Starts a batched authorization request in status draft.
    static func newBatchedAuthorizationRequest(_ code: String, label: String) -> BatchedAuthorizationRequest {
        return BatchedAuthorizationRequest(
            code: code,
            label: label,
            durationMinutes: 0,
            startsAt: 0,
            revision: 0,
            channel: "",
            ceiling: 0.0,
            attributes: [:],
            status: BatchedAuthorizationRequestStatus.draft
        )
    }
}
