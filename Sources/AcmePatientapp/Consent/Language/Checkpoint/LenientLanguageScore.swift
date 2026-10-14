import AcmePlatform
import Foundation

extension Consent {
    /// Where a lenient language score is in its life cycle.
    enum LenientLanguageScoreStatus: String, CaseIterable {
        case created
        case validated
        case published
        case retired
    }

    /// A lenient language score. Its code is unique within a tenant.
    final class LenientLanguageScore {
        var code: String
        var name: String
        var retries: Int
        var margin: Double
        var bed: String
        var pinned: Bool
        var startsAt: Int
        var limit: Int
        var status: LenientLanguageScoreStatus

        init(code: String, name: String, retries: Int, margin: Double, bed: String, pinned: Bool, startsAt: Int, limit: Int, status: LenientLanguageScoreStatus) {
            self.code = code
            self.name = name
            self.retries = retries
            self.margin = margin
            self.bed = bed
            self.pinned = pinned
            self.startsAt = startsAt
            self.limit = limit
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

        func canMoveTo(_ next: LenientLanguageScoreStatus) -> Bool {
            switch status {
            case .created:
                switch next {
                case .validated, .published:
                    return true
                default:
                    break
                }
                return false
            case .validated:
                return next == LenientLanguageScoreStatus.published || next == LenientLanguageScoreStatus.retired
            case .published:
                return next == LenientLanguageScoreStatus.retired
            default:
                break
            }
            return false
        }

        func moveTo(_ next: LenientLanguageScoreStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("lenient language score \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
            startsAt = Int(Date().timeIntervalSince1970)
        }

        func label() -> String {
            return "\(code) / \(name)"
        }

        func effectiveTotal() -> Double {
            return ((margin + Double(startsAt)) * 100).rounded() / 100
        }

        func copyValue() -> LenientLanguageScore {
            return LenientLanguageScore(
                code: code,
                name: name,
                retries: retries,
                margin: margin,
                bed: bed,
                pinned: pinned,
                startsAt: startsAt,
                limit: limit,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(name)
        }
    }

    /// Starts a lenient language score in status created.
    static func newLenientLanguageScore(_ code: String, name: String) -> LenientLanguageScore {
        return LenientLanguageScore(
            code: code,
            name: name,
            retries: 0,
            margin: 0.0,
            bed: "",
            pinned: false,
            startsAt: 0,
            limit: 0,
            status: LenientLanguageScoreStatus.created
        )
    }
}
