import AcmePlatform
import Foundation

extension Pharmacy {
    /// Where a capped formulary review is in its life cycle.
    enum CappedFormularyReviewStatus: String, CaseIterable {
        case requested
        case granted
        case revoked
        case expired
    }

    /// A capped formulary review as the formulary team keeps it.
    final class CappedFormularyReview {
        var code: String
        var title: String
        var batchSize: Int
        var acuity: Int
        var revision: Int
        var diagnosisCode: String
        var status: CappedFormularyReviewStatus

        init(code: String, title: String, batchSize: Int, acuity: Int, revision: Int, diagnosisCode: String, status: CappedFormularyReviewStatus) {
            self.code = code
            self.title = title
            self.batchSize = batchSize
            self.acuity = acuity
            self.revision = revision
            self.diagnosisCode = diagnosisCode
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

        func canMoveTo(_ next: CappedFormularyReviewStatus) -> Bool {
            switch status {
            case .requested:
                switch next {
                case .granted, .revoked:
                    return true
                default:
                    break
                }
                return false
            case .granted:
                return next == CappedFormularyReviewStatus.revoked || next == CappedFormularyReviewStatus.expired
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

        func moveTo(_ next: CappedFormularyReviewStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("capped formulary review \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
            revision += 1
        }

        func label() -> String {
            return "\(code) [\(title)]"
        }

        func effectiveVolume() -> Double {
            return ((Double(batchSize) - Double(revision)) * 100).rounded() / 100
        }

        func copyValue() -> CappedFormularyReview {
            return CappedFormularyReview(
                code: code,
                title: title,
                batchSize: batchSize,
                acuity: acuity,
                revision: revision,
                diagnosisCode: diagnosisCode,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(title)
        }
    }

    /// Starts a capped formulary review in status requested.
    static func newCappedFormularyReview(_ code: String, title: String) -> CappedFormularyReview {
        return CappedFormularyReview(
            code: code,
            title: title,
            batchSize: 0,
            acuity: 0,
            revision: 0,
            diagnosisCode: "",
            status: CappedFormularyReviewStatus.requested
        )
    }
}
