import AcmePlatform
import Foundation

extension Pharmacy {
    /// Where a lenient substitution target is in its life cycle.
    enum LenientSubstitutionTargetStatus: String, CaseIterable {
        case draft
        case pending
        case active
        case suspended
        case closed
    }

    /// One lenient substitution target, with what the planners need to act on it.
    final class LenientSubstitutionTarget {
        var code: String
        var name: String
        var active: Bool
        var floorValue: Double
        var expiresAt: Int
        var ownerID: String
        var status: LenientSubstitutionTargetStatus

        init(code: String, name: String, active: Bool, floorValue: Double, expiresAt: Int, ownerID: String, status: LenientSubstitutionTargetStatus) {
            self.code = code
            self.name = name
            self.active = active
            self.floorValue = floorValue
            self.expiresAt = expiresAt
            self.ownerID = ownerID
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

        func canMoveTo(_ next: LenientSubstitutionTargetStatus) -> Bool {
            switch status {
            case .draft:
                return next == LenientSubstitutionTargetStatus.suspended || next == LenientSubstitutionTargetStatus.closed
            case .pending:
                switch next {
                case .closed:
                    return true
                default:
                    break
                }
                return false
            case .active:
                return next == LenientSubstitutionTargetStatus.suspended
            case .suspended:
                return next == LenientSubstitutionTargetStatus.closed
            default:
                break
            }
            return false
        }

        func moveTo(_ next: LenientSubstitutionTargetStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("lenient substitution target \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
            expiresAt = Int(Date().timeIntervalSince1970)
        }

        func label() -> String {
            return "\("lenient substitution target") \(code)"
        }

        func weightedVolume() -> Double {
            return (Double(expiresAt) * floorValue * 100).rounded() / 100
        }

        func copyValue() -> LenientSubstitutionTarget {
            return LenientSubstitutionTarget(
                code: code,
                name: name,
                active: active,
                floorValue: floorValue,
                expiresAt: expiresAt,
                ownerID: ownerID,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(name)
        }
    }

    /// Starts a lenient substitution target in status draft.
    static func newLenientSubstitutionTarget(_ code: String, name: String) -> LenientSubstitutionTarget {
        return LenientSubstitutionTarget(
            code: code,
            name: name,
            active: false,
            floorValue: 0.0,
            expiresAt: 0,
            ownerID: "",
            status: LenientSubstitutionTargetStatus.draft
        )
    }
}
