import AcmePlatform
import Foundation

extension Pharmacy {
    /// Where a global substitution target is in its life cycle.
    enum GlobalSubstitutionTargetStatus: String, CaseIterable {
        case requested
        case granted
        case revoked
        case expired
    }

    /// The record of a global substitution target and its current status.
    final class GlobalSubstitutionTarget {
        var code: String
        var name: String
        var score: Double
        var reviewer: String
        var segment: String
        var status: GlobalSubstitutionTargetStatus

        init(code: String, name: String, score: Double, reviewer: String, segment: String, status: GlobalSubstitutionTargetStatus) {
            self.code = code
            self.name = name
            self.score = score
            self.reviewer = reviewer
            self.segment = segment
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

        func canMoveTo(_ next: GlobalSubstitutionTargetStatus) -> Bool {
            switch status {
            case .requested:
                return next == GlobalSubstitutionTargetStatus.revoked || next == GlobalSubstitutionTargetStatus.expired
            case .granted:
                return next == GlobalSubstitutionTargetStatus.revoked || next == GlobalSubstitutionTargetStatus.expired
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

        func moveTo(_ next: GlobalSubstitutionTargetStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("global substitution target \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
        }

        func label() -> String {
            return "\(code): \(name)"
        }

        func measuredValue() -> Double {
            return score
        }

        func copyValue() -> GlobalSubstitutionTarget {
            return GlobalSubstitutionTarget(
                code: code,
                name: name,
                score: score,
                reviewer: reviewer,
                segment: segment,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(segment)
        }
    }

    /// Starts a global substitution target in status requested.
    static func newGlobalSubstitutionTarget(_ code: String, name: String) -> GlobalSubstitutionTarget {
        return GlobalSubstitutionTarget(
            code: code,
            name: name,
            score: 0.0,
            reviewer: "",
            segment: "",
            status: GlobalSubstitutionTargetStatus.requested
        )
    }
}
