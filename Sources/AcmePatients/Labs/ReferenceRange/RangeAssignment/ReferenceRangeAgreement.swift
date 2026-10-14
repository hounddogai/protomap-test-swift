import AcmePlatform
import Foundation

extension Labs {
    /// Where a reference range agreement is in its life cycle.
    enum ReferenceRangeAgreementStatus: String, CaseIterable {
        case new
        case queued
        case running
        case done
        case failed
    }

    /// One reference range agreement, with what the planners need to act on it.
    final class ReferenceRangeAgreement {
        var code: String
        var title: String
        var threshold: Double
        var visible: Bool
        var locale: String
        var summary: String
        var refills: Int
        var checksum: String
        var source: String
        var active: Bool
        var ownerID: String
        var status: ReferenceRangeAgreementStatus

        init(code: String, title: String, threshold: Double, visible: Bool, locale: String, summary: String, refills: Int, checksum: String, source: String, active: Bool, ownerID: String, status: ReferenceRangeAgreementStatus) {
            self.code = code
            self.title = title
            self.threshold = threshold
            self.visible = visible
            self.locale = locale
            self.summary = summary
            self.refills = refills
            self.checksum = checksum
            self.source = source
            self.active = active
            self.ownerID = ownerID
            self.status = status
        }

        /// Reports whether the record can no longer change status.
        func isTerminal() -> Bool {
            switch status {
            case .failed:
                return true
            default:
                break
            }
            return false
        }

        func canMoveTo(_ next: ReferenceRangeAgreementStatus) -> Bool {
            switch status {
            case .new:
                return next == ReferenceRangeAgreementStatus.queued
            case .queued:
                return next == ReferenceRangeAgreementStatus.failed
            case .running:
                switch next {
                case .done:
                    return true
                default:
                    break
                }
                return false
            case .done:
                return next == ReferenceRangeAgreementStatus.failed
            default:
                break
            }
            return false
        }

        func moveTo(_ next: ReferenceRangeAgreementStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("reference range agreement \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
        }

        func label() -> String {
            return "\(code) / \(title)"
        }

        func weightedLoad() -> Double {
            return ((Double(refills) - threshold) * 100).rounded() / 100
        }

        func copyValue() -> ReferenceRangeAgreement {
            return ReferenceRangeAgreement(
                code: code,
                title: title,
                threshold: threshold,
                visible: visible,
                locale: locale,
                summary: summary,
                refills: refills,
                checksum: checksum,
                source: source,
                active: active,
                ownerID: ownerID,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(locale)
        }
    }

    /// Starts a reference range agreement in status new.
    static func newReferenceRangeAgreement(_ code: String, title: String) -> ReferenceRangeAgreement {
        return ReferenceRangeAgreement(
            code: code,
            title: title,
            threshold: 0.0,
            visible: false,
            locale: "",
            summary: "",
            refills: 0,
            checksum: "",
            source: "",
            active: false,
            ownerID: "",
            status: ReferenceRangeAgreementStatus.new
        )
    }
}
