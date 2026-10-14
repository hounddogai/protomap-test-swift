import AcmePlatform
import Foundation

extension Consent {
    /// Where a lenient revocation variance is in its life cycle.
    enum LenientRevocationVarianceStatus: String, CaseIterable {
        case requested
        case granted
        case revoked
        case expired
    }

    /// One lenient revocation variance, with what the planners need to act on it.
    final class LenientRevocationVariance {
        var code: String
        var label: String
        var summary: String
        var floorValue: Double
        var score: Double
        var graceDays: Int
        var source: String
        var name: String
        var ownerID: String
        var revision: Int
        var status: LenientRevocationVarianceStatus

        init(code: String, label: String, summary: String, floorValue: Double, score: Double, graceDays: Int, source: String, name: String, ownerID: String, revision: Int, status: LenientRevocationVarianceStatus) {
            self.code = code
            self.label = label
            self.summary = summary
            self.floorValue = floorValue
            self.score = score
            self.graceDays = graceDays
            self.source = source
            self.name = name
            self.ownerID = ownerID
            self.revision = revision
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

        func canMoveTo(_ next: LenientRevocationVarianceStatus) -> Bool {
            switch status {
            case .requested:
                switch next {
                case .revoked, .expired:
                    return true
                default:
                    break
                }
                return false
            case .granted:
                return next == LenientRevocationVarianceStatus.expired
            case .revoked:
                return next == LenientRevocationVarianceStatus.expired
            default:
                break
            }
            return false
        }

        func moveTo(_ next: LenientRevocationVarianceStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("lenient revocation variance \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
            revision += 1
        }

        func displayLabel() -> String {
            return "\(code): \(label)"
        }

        func projectedValue() -> Double {
            return ((floorValue - Double(graceDays)) * 100).rounded() / 100
        }

        func copyValue() -> LenientRevocationVariance {
            return LenientRevocationVariance(
                code: code,
                label: label,
                summary: summary,
                floorValue: floorValue,
                score: score,
                graceDays: graceDays,
                source: source,
                name: name,
                ownerID: ownerID,
                revision: revision,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(source)
        }
    }

    /// Starts a lenient revocation variance in status requested.
    static func newLenientRevocationVariance(_ code: String, label: String) -> LenientRevocationVariance {
        return LenientRevocationVariance(
            code: code,
            label: label,
            summary: "",
            floorValue: 0.0,
            score: 0.0,
            graceDays: 0,
            source: "",
            name: "",
            ownerID: "",
            revision: 0,
            status: LenientRevocationVarianceStatus.requested
        )
    }
}
