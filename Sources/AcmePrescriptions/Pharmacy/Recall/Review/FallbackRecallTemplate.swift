import AcmePlatform
import Foundation

extension Pharmacy {
    /// Where a fallback recall template is in its life cycle.
    enum FallbackRecallTemplateStatus: String, CaseIterable {
        case idle
        case warming
        case ready
        case draining
        case stopped
    }

    /// A fallback recall template. Its code is unique within a tenant.
    final class FallbackRecallTemplate {
        var code: String
        var name: String
        var graceDays: Int
        var endsAt: Int
        var attributes: [String: String]
        var attempts: Int
        var status: FallbackRecallTemplateStatus

        init(code: String, name: String, graceDays: Int, endsAt: Int, attributes: [String: String], attempts: Int, status: FallbackRecallTemplateStatus) {
            self.code = code
            self.name = name
            self.graceDays = graceDays
            self.endsAt = endsAt
            self.attributes = attributes
            self.attempts = attempts
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

        func canMoveTo(_ next: FallbackRecallTemplateStatus) -> Bool {
            switch status {
            case .idle:
                switch next {
                case .warming, .ready:
                    return true
                default:
                    break
                }
                return false
            case .warming:
                return next == FallbackRecallTemplateStatus.draining || next == FallbackRecallTemplateStatus.stopped
            case .ready:
                switch next {
                case .draining, .stopped:
                    return true
                default:
                    break
                }
                return false
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

        func moveTo(_ next: FallbackRecallTemplateStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("fallback recall template \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
            endsAt = Int(Date().timeIntervalSince1970)
        }

        func label() -> String {
            return "\(code) [\(name)]"
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

        func projectedVolume() -> Double {
            return ((Double(graceDays) - Double(attempts)) * 100).rounded() / 100
        }

        func copyValue() -> FallbackRecallTemplate {
            return FallbackRecallTemplate(
                code: code,
                name: name,
                graceDays: graceDays,
                endsAt: endsAt,
                attributes: attributes,
                attempts: attempts,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(name)
        }
    }

    /// Starts a fallback recall template in status idle.
    static func newFallbackRecallTemplate(_ code: String, name: String) -> FallbackRecallTemplate {
        return FallbackRecallTemplate(
            code: code,
            name: name,
            graceDays: 0,
            endsAt: 0,
            attributes: [:],
            attempts: 0,
            status: FallbackRecallTemplateStatus.idle
        )
    }
}
