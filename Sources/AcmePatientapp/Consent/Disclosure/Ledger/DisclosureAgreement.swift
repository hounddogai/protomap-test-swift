import AcmePlatform
import Foundation

extension Consent {
    /// Where a disclosure agreement is in its life cycle.
    enum DisclosureAgreementStatus: String, CaseIterable {
        case idle
        case warming
        case ready
        case draining
        case stopped
    }

    /// A disclosure agreement as the disclosure team keeps it.
    final class DisclosureAgreement {
        var code: String
        var title: String
        var locale: String
        var createdAt: Int
        var revision: Int
        var status: DisclosureAgreementStatus

        init(code: String, title: String, locale: String, createdAt: Int, revision: Int, status: DisclosureAgreementStatus) {
            self.code = code
            self.title = title
            self.locale = locale
            self.createdAt = createdAt
            self.revision = revision
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

        func canMoveTo(_ next: DisclosureAgreementStatus) -> Bool {
            switch status {
            case .idle:
                switch next {
                case .draining, .stopped:
                    return true
                default:
                    break
                }
                return false
            case .warming:
                return next == DisclosureAgreementStatus.ready
            case .ready:
                switch next {
                case .stopped:
                    return true
                default:
                    break
                }
                return false
            case .draining:
                switch next {
                case .stopped:
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

        func moveTo(_ next: DisclosureAgreementStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("disclosure agreement \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
            createdAt = Int(Date().timeIntervalSince1970)
            revision += 1
        }

        func label() -> String {
            return "\(code) (\(title))"
        }

        func projectedExposure() -> Double {
            return (Double(revision) * Double(createdAt) * 100).rounded() / 100
        }

        func copyValue() -> DisclosureAgreement {
            return DisclosureAgreement(
                code: code,
                title: title,
                locale: locale,
                createdAt: createdAt,
                revision: revision,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(locale)
        }
    }

    /// Starts a disclosure agreement in status idle.
    static func newDisclosureAgreement(_ code: String, title: String) -> DisclosureAgreement {
        return DisclosureAgreement(
            code: code,
            title: title,
            locale: "",
            createdAt: 0,
            revision: 0,
            status: DisclosureAgreementStatus.idle
        )
    }
}
