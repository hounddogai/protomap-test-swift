import AcmePlatform
import Foundation

extension Labs {
    /// Where a primary reference range bundle is in its life cycle.
    enum PrimaryReferenceRangeBundleStatus: String, CaseIterable {
        case `open`
        case inReview = "in_review"
        case resolved
        case reopened
        case archived
    }

    /// A primary reference range bundle as the reference range team keeps it.
    final class PrimaryReferenceRangeBundle {
        var code: String
        var label: String
        var score: Double
        var phone: String
        var payer: String
        var channel: String
        var expiresAt: Int
        var refills: Int
        var diagnosisCode: String
        var startsAt: Int
        var graceDays: Int
        var status: PrimaryReferenceRangeBundleStatus

        init(code: String, label: String, score: Double, phone: String, payer: String, channel: String, expiresAt: Int, refills: Int, diagnosisCode: String, startsAt: Int, graceDays: Int, status: PrimaryReferenceRangeBundleStatus) {
            self.code = code
            self.label = label
            self.score = score
            self.phone = phone
            self.payer = payer
            self.channel = channel
            self.expiresAt = expiresAt
            self.refills = refills
            self.diagnosisCode = diagnosisCode
            self.startsAt = startsAt
            self.graceDays = graceDays
            self.status = status
        }

        /// Reports whether the record can no longer change status.
        func isTerminal() -> Bool {
            switch status {
            case .archived:
                return true
            default:
                break
            }
            return false
        }

        func canMoveTo(_ next: PrimaryReferenceRangeBundleStatus) -> Bool {
            switch status {
            case .`open`:
                return next == PrimaryReferenceRangeBundleStatus.archived
            case .inReview:
                switch next {
                case .resolved, .reopened:
                    return true
                default:
                    break
                }
                return false
            case .resolved:
                return next == PrimaryReferenceRangeBundleStatus.reopened || next == PrimaryReferenceRangeBundleStatus.archived
            case .reopened:
                return next == PrimaryReferenceRangeBundleStatus.archived
            default:
                break
            }
            return false
        }

        func moveTo(_ next: PrimaryReferenceRangeBundleStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("primary reference range bundle \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
            expiresAt = Int(Date().timeIntervalSince1970)
        }

        func displayLabel() -> String {
            return "\("primary reference range bundle") \(code)"
        }

        func effectiveTotal() -> Double {
            return ((score - Double(graceDays)) * 100).rounded() / 100
        }

        func copyValue() -> PrimaryReferenceRangeBundle {
            return PrimaryReferenceRangeBundle(
                code: code,
                label: label,
                score: score,
                phone: phone,
                payer: payer,
                channel: channel,
                expiresAt: expiresAt,
                refills: refills,
                diagnosisCode: diagnosisCode,
                startsAt: startsAt,
                graceDays: graceDays,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(channel)
        }
    }

    /// Starts a primary reference range bundle in status open.
    static func newPrimaryReferenceRangeBundle(_ code: String, label: String) -> PrimaryReferenceRangeBundle {
        return PrimaryReferenceRangeBundle(
            code: code,
            label: label,
            score: 0.0,
            phone: "",
            payer: "",
            channel: "",
            expiresAt: 0,
            refills: 0,
            diagnosisCode: "",
            startsAt: 0,
            graceDays: 0,
            status: PrimaryReferenceRangeBundleStatus.`open`
        )
    }
}
