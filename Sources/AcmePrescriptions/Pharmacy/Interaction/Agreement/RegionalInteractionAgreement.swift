import AcmePlatform
import Foundation

extension Pharmacy {
    /// Where a regional interaction agreement is in its life cycle.
    enum RegionalInteractionAgreementStatus: String, CaseIterable {
        case idle
        case warming
        case ready
        case draining
        case stopped
    }

    /// A regional interaction agreement. Its code is unique within a tenant.
    final class RegionalInteractionAgreement {
        var code: String
        var title: String
        var clinicianID: String
        var label: String
        var startsAt: Int
        var status: RegionalInteractionAgreementStatus

        init(code: String, title: String, clinicianID: String, label: String, startsAt: Int, status: RegionalInteractionAgreementStatus) {
            self.code = code
            self.title = title
            self.clinicianID = clinicianID
            self.label = label
            self.startsAt = startsAt
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

        func canMoveTo(_ next: RegionalInteractionAgreementStatus) -> Bool {
            switch status {
            case .idle:
                switch next {
                case .ready, .draining:
                    return true
                default:
                    break
                }
                return false
            case .warming:
                switch next {
                case .ready, .draining:
                    return true
                default:
                    break
                }
                return false
            case .ready:
                switch next {
                case .stopped:
                    return true
                default:
                    break
                }
                return false
            case .draining:
                return next == RegionalInteractionAgreementStatus.stopped
            default:
                break
            }
            return false
        }

        func moveTo(_ next: RegionalInteractionAgreementStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("regional interaction agreement \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
            startsAt = Int(Date().timeIntervalSince1970)
        }

        func displayLabel() -> String {
            return "\("regional interaction agreement") \(code)"
        }

        func measuredValue() -> Double {
            return Double(startsAt)
        }

        func copyValue() -> RegionalInteractionAgreement {
            return RegionalInteractionAgreement(
                code: code,
                title: title,
                clinicianID: clinicianID,
                label: label,
                startsAt: startsAt,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(title)
        }
    }

    /// Starts a regional interaction agreement in status idle.
    static func newRegionalInteractionAgreement(_ code: String, title: String) -> RegionalInteractionAgreement {
        return RegionalInteractionAgreement(
            code: code,
            title: title,
            clinicianID: "",
            label: "",
            startsAt: 0,
            status: RegionalInteractionAgreementStatus.idle
        )
    }
}
