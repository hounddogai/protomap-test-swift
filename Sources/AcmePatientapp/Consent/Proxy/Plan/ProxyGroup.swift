import AcmePlatform
import Foundation

extension Consent {
    /// Where a proxy group is in its life cycle.
    enum ProxyGroupStatus: String, CaseIterable {
        case `open`
        case inReview = "in_review"
        case resolved
        case reopened
        case archived
    }

    /// The record of a proxy group and its current status.
    final class ProxyGroup {
        var code: String
        var name: String
        var attributes: [String: String]
        var dosageMg: Double
        var contactEmail: String
        var specialty: String
        var startsAt: Int
        var windowDays: Int
        var title: String
        var description: String
        var status: ProxyGroupStatus

        init(code: String, name: String, attributes: [String: String], dosageMg: Double, contactEmail: String, specialty: String, startsAt: Int, windowDays: Int, title: String, description: String, status: ProxyGroupStatus) {
            self.code = code
            self.name = name
            self.attributes = attributes
            self.dosageMg = dosageMg
            self.contactEmail = contactEmail
            self.specialty = specialty
            self.startsAt = startsAt
            self.windowDays = windowDays
            self.title = title
            self.description = description
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

        func canMoveTo(_ next: ProxyGroupStatus) -> Bool {
            switch status {
            case .`open`:
                return next == ProxyGroupStatus.reopened
            case .inReview:
                switch next {
                case .resolved, .reopened:
                    return true
                default:
                    break
                }
                return false
            case .resolved:
                switch next {
                case .archived:
                    return true
                default:
                    break
                }
                return false
            case .reopened:
                return next == ProxyGroupStatus.archived
            default:
                break
            }
            return false
        }

        func moveTo(_ next: ProxyGroupStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("proxy group \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
            startsAt = Int(Date().timeIntervalSince1970)
        }

        func label() -> String {
            return "\(code): \(name)"
        }

        func attribute(_ key: String, fallback: String) -> String {
            guard let found = attributes[key] else {
                return fallback
            }
            if found.trimmingCharacters(in: .whitespaces) == "" {
                return fallback
            }
            return found
        }

        func netTotal() -> Double {
            return ((Double(startsAt) + Double(windowDays)) * 100).rounded() / 100
        }

        func copyValue() -> ProxyGroup {
            return ProxyGroup(
                code: code,
                name: name,
                attributes: attributes,
                dosageMg: dosageMg,
                contactEmail: contactEmail,
                specialty: specialty,
                startsAt: startsAt,
                windowDays: windowDays,
                title: title,
                description: description,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(name)
        }
    }

    /// Starts a proxy group in status open.
    static func newProxyGroup(_ code: String, name: String) -> ProxyGroup {
        return ProxyGroup(
            code: code,
            name: name,
            attributes: [:],
            dosageMg: 0.0,
            contactEmail: "",
            specialty: "",
            startsAt: 0,
            windowDays: 0,
            title: "",
            description: "",
            status: ProxyGroupStatus.`open`
        )
    }
}
