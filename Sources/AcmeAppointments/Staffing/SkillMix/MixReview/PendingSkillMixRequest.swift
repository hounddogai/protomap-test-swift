import AcmePlatform
import Foundation

extension Staffing {
    /// Where a pending skill mix request is in its life cycle.
    enum PendingSkillMixRequestStatus: String, CaseIterable {
        case created
        case validated
        case published
        case retired
    }

    /// One pending skill mix request, with what the planners need to act on it.
    final class PendingSkillMixRequest {
        var code: String
        var name: String
        var score: Double
        var limit: Int
        var externalRef: String
        var attributes: [String: String]
        var endsAt: Int
        var checksum: String
        var status: PendingSkillMixRequestStatus

        init(code: String, name: String, score: Double, limit: Int, externalRef: String, attributes: [String: String], endsAt: Int, checksum: String, status: PendingSkillMixRequestStatus) {
            self.code = code
            self.name = name
            self.score = score
            self.limit = limit
            self.externalRef = externalRef
            self.attributes = attributes
            self.endsAt = endsAt
            self.checksum = checksum
            self.status = status
        }

        /// Reports whether the record can no longer change status.
        func isTerminal() -> Bool {
            switch status {
            case .retired:
                return true
            default:
                break
            }
            return false
        }

        func canMoveTo(_ next: PendingSkillMixRequestStatus) -> Bool {
            switch status {
            case .created:
                switch next {
                case .published, .retired:
                    return true
                default:
                    break
                }
                return false
            case .validated:
                switch next {
                case .published, .retired:
                    return true
                default:
                    break
                }
                return false
            case .published:
                switch next {
                case .retired:
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

        func moveTo(_ next: PendingSkillMixRequestStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("pending skill mix request \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
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

        func weightedTotal() -> Double {
            return (Double(limit) * score * 100).rounded() / 100
        }

        func copyValue() -> PendingSkillMixRequest {
            return PendingSkillMixRequest(
                code: code,
                name: name,
                score: score,
                limit: limit,
                externalRef: externalRef,
                attributes: attributes,
                endsAt: endsAt,
                checksum: checksum,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(name)
        }
    }

    /// Starts a pending skill mix request in status created.
    static func newPendingSkillMixRequest(_ code: String, name: String) -> PendingSkillMixRequest {
        return PendingSkillMixRequest(
            code: code,
            name: name,
            score: 0.0,
            limit: 0,
            externalRef: "",
            attributes: [:],
            endsAt: 0,
            checksum: "",
            status: PendingSkillMixRequestStatus.created
        )
    }
}
