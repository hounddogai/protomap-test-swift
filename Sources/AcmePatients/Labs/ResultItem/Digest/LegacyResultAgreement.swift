import AcmePlatform
import Foundation

extension Labs {
    /// Where a legacy result agreement is in its life cycle.
    enum LegacyResultAgreementStatus: String, CaseIterable {
        case idle
        case warming
        case ready
        case draining
        case stopped
    }

    /// One legacy result agreement, with what the planners need to act on it.
    final class LegacyResultAgreement {
        var code: String
        var title: String
        var segment: String
        var margin: Double
        var clinicianID: String
        var source: String
        var contactEmail: String
        var status: LegacyResultAgreementStatus

        init(code: String, title: String, segment: String, margin: Double, clinicianID: String, source: String, contactEmail: String, status: LegacyResultAgreementStatus) {
            self.code = code
            self.title = title
            self.segment = segment
            self.margin = margin
            self.clinicianID = clinicianID
            self.source = source
            self.contactEmail = contactEmail
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

        func canMoveTo(_ next: LegacyResultAgreementStatus) -> Bool {
            switch status {
            case .idle:
                return next == LegacyResultAgreementStatus.ready || next == LegacyResultAgreementStatus.draining
            case .warming:
                return next == LegacyResultAgreementStatus.draining || next == LegacyResultAgreementStatus.stopped
            case .ready:
                return next == LegacyResultAgreementStatus.draining || next == LegacyResultAgreementStatus.stopped
            case .draining:
                return next == LegacyResultAgreementStatus.stopped
            default:
                break
            }
            return false
        }

        func moveTo(_ next: LegacyResultAgreementStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("legacy result agreement \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
        }

        func label() -> String {
            return "\("legacy result agreement") \(code)"
        }

        func measuredValue() -> Double {
            return margin
        }

        func copyValue() -> LegacyResultAgreement {
            return LegacyResultAgreement(
                code: code,
                title: title,
                segment: segment,
                margin: margin,
                clinicianID: clinicianID,
                source: source,
                contactEmail: contactEmail,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(segment)
        }
    }

    /// Starts a legacy result agreement in status idle.
    static func newLegacyResultAgreement(_ code: String, title: String) -> LegacyResultAgreement {
        return LegacyResultAgreement(
            code: code,
            title: title,
            segment: "",
            margin: 0.0,
            clinicianID: "",
            source: "",
            contactEmail: "",
            status: LegacyResultAgreementStatus.idle
        )
    }
}
