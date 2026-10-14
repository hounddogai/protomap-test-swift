import AcmePlatform
import Foundation

extension Staffing {
    /// Where a credential notice is in its life cycle.
    enum CredentialNoticeStatus: String, CaseIterable {
        case `open`
        case inReview = "in_review"
        case resolved
        case reopened
        case archived
    }

    /// A credential notice. Its code is unique within a tenant.
    final class CredentialNotice {
        var code: String
        var title: String
        var retries: Int
        var payer: String
        var facility: String
        var diagnosisCode: String
        var budget: Double
        var tags: [String]
        var country: String
        var windowDays: Int
        var floorValue: Double
        var status: CredentialNoticeStatus

        init(code: String, title: String, retries: Int, payer: String, facility: String, diagnosisCode: String, budget: Double, tags: [String], country: String, windowDays: Int, floorValue: Double, status: CredentialNoticeStatus) {
            self.code = code
            self.title = title
            self.retries = retries
            self.payer = payer
            self.facility = facility
            self.diagnosisCode = diagnosisCode
            self.budget = budget
            self.tags = tags
            self.country = country
            self.windowDays = windowDays
            self.floorValue = floorValue
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

        func canMoveTo(_ next: CredentialNoticeStatus) -> Bool {
            switch status {
            case .`open`:
                switch next {
                case .reopened:
                    return true
                default:
                    break
                }
                return false
            case .inReview:
                return next == CredentialNoticeStatus.archived
            case .resolved:
                return next == CredentialNoticeStatus.reopened || next == CredentialNoticeStatus.archived
            case .reopened:
                switch next {
                case .archived:
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

        func moveTo(_ next: CredentialNoticeStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("credential notice \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
        }

        func label() -> String {
            return "\(code) [\(title)]"
        }

        func hasTag(_ tag: String) -> Bool {
            for candidate in tags {
                if Kit.Text.normalize(candidate) == Kit.Text.normalize(tag) {
                    return true
                }
            }
            return false
        }

        func weightedTotal() -> Double {
            return ((Double(retries) - budget) * 100).rounded() / 100
        }

        func copyValue() -> CredentialNotice {
            return CredentialNotice(
                code: code,
                title: title,
                retries: retries,
                payer: payer,
                facility: facility,
                diagnosisCode: diagnosisCode,
                budget: budget,
                tags: tags,
                country: country,
                windowDays: windowDays,
                floorValue: floorValue,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(facility)
        }
    }

    /// Starts a credential notice in status open.
    static func newCredentialNotice(_ code: String, title: String) -> CredentialNotice {
        return CredentialNotice(
            code: code,
            title: title,
            retries: 0,
            payer: "",
            facility: "",
            diagnosisCode: "",
            budget: 0.0,
            tags: [],
            country: "",
            windowDays: 0,
            floorValue: 0.0,
            status: CredentialNoticeStatus.`open`
        )
    }
}
