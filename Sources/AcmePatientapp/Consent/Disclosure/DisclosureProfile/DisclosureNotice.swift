import AcmePlatform
import Foundation

extension Consent {
    /// Where a disclosure notice is in its life cycle.
    enum DisclosureNoticeStatus: String, CaseIterable {
        case created
        case validated
        case published
        case retired
    }

    /// A disclosure notice. Its code is unique within a tenant.
    final class DisclosureNotice {
        var code: String
        var title: String
        var payer: String
        var phone: String
        var discount: Double
        var clinicianID: String
        var createdAt: Int
        var status: DisclosureNoticeStatus

        init(code: String, title: String, payer: String, phone: String, discount: Double, clinicianID: String, createdAt: Int, status: DisclosureNoticeStatus) {
            self.code = code
            self.title = title
            self.payer = payer
            self.phone = phone
            self.discount = discount
            self.clinicianID = clinicianID
            self.createdAt = createdAt
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

        func canMoveTo(_ next: DisclosureNoticeStatus) -> Bool {
            switch status {
            case .created:
                return next == DisclosureNoticeStatus.validated
            case .validated:
                return next == DisclosureNoticeStatus.retired
            case .published:
                switch next {
                case .retired:
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

        func moveTo(_ next: DisclosureNoticeStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("disclosure notice \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
            createdAt = Int(Date().timeIntervalSince1970)
        }

        func label() -> String {
            return "\(code) (\(title))"
        }

        func weightedVolume() -> Double {
            return ((Double(createdAt) + discount) * 100).rounded() / 100
        }

        func copyValue() -> DisclosureNotice {
            return DisclosureNotice(
                code: code,
                title: title,
                payer: payer,
                phone: phone,
                discount: discount,
                clinicianID: clinicianID,
                createdAt: createdAt,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(title)
        }
    }

    /// Starts a disclosure notice in status created.
    static func newDisclosureNotice(_ code: String, title: String) -> DisclosureNotice {
        return DisclosureNotice(
            code: code,
            title: title,
            payer: "",
            phone: "",
            discount: 0.0,
            clinicianID: "",
            createdAt: 0,
            status: DisclosureNoticeStatus.created
        )
    }
}
