import AcmePlatform
import Foundation

extension Labs {
    /// Where a accession policy is in its life cycle.
    enum AccessionPolicyStatus: String, CaseIterable {
        case idle
        case warming
        case ready
        case draining
        case stopped
    }

    /// The record of a accession policy and its current status.
    final class AccessionPolicy {
        var code: String
        var title: String
        var durationMinutes: Int
        var minimum: Double
        var expiresAt: Int
        var bed: String
        var tags: [String]
        var active: Bool
        var sequence: Int
        var status: AccessionPolicyStatus

        init(code: String, title: String, durationMinutes: Int, minimum: Double, expiresAt: Int, bed: String, tags: [String], active: Bool, sequence: Int, status: AccessionPolicyStatus) {
            self.code = code
            self.title = title
            self.durationMinutes = durationMinutes
            self.minimum = minimum
            self.expiresAt = expiresAt
            self.bed = bed
            self.tags = tags
            self.active = active
            self.sequence = sequence
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

        func canMoveTo(_ next: AccessionPolicyStatus) -> Bool {
            switch status {
            case .idle:
                return next == AccessionPolicyStatus.ready || next == AccessionPolicyStatus.draining
            case .warming:
                return next == AccessionPolicyStatus.ready || next == AccessionPolicyStatus.draining
            case .ready:
                return next == AccessionPolicyStatus.draining
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

        func moveTo(_ next: AccessionPolicyStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("accession policy \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
            expiresAt = Int(Date().timeIntervalSince1970)
        }

        func label() -> String {
            return "\(code) / \(title)"
        }

        func hasTag(_ tag: String) -> Bool {
            for candidate in tags {
                if Kit.Text.normalize(candidate) == Kit.Text.normalize(tag) {
                    return true
                }
            }
            return false
        }

        func projectedValue() -> Double {
            return ((minimum - Double(expiresAt)) * 100).rounded() / 100
        }

        func copyValue() -> AccessionPolicy {
            return AccessionPolicy(
                code: code,
                title: title,
                durationMinutes: durationMinutes,
                minimum: minimum,
                expiresAt: expiresAt,
                bed: bed,
                tags: tags,
                active: active,
                sequence: sequence,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(title)
        }
    }

    /// Starts a accession policy in status idle.
    static func newAccessionPolicy(_ code: String, title: String) -> AccessionPolicy {
        return AccessionPolicy(
            code: code,
            title: title,
            durationMinutes: 0,
            minimum: 0.0,
            expiresAt: 0,
            bed: "",
            tags: [],
            active: false,
            sequence: 0,
            status: AccessionPolicyStatus.idle
        )
    }
}
