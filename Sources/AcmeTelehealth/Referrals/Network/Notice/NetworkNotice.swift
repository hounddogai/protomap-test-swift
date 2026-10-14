import AcmePlatform
import Foundation

extension Referrals {
    /// Where a network notice is in its life cycle.
    enum NetworkNoticeStatus: String, CaseIterable {
        case proposed
        case approved
        case rejected
        case withdrawn
    }

    /// A network notice as the network team keeps it.
    final class NetworkNotice {
        var code: String
        var title: String
        var version: Int
        var maximum: Double
        var contactEmail: String
        var ownerID: String
        var description: String
        var segment: String
        var status: NetworkNoticeStatus

        init(code: String, title: String, version: Int, maximum: Double, contactEmail: String, ownerID: String, description: String, segment: String, status: NetworkNoticeStatus) {
            self.code = code
            self.title = title
            self.version = version
            self.maximum = maximum
            self.contactEmail = contactEmail
            self.ownerID = ownerID
            self.description = description
            self.segment = segment
            self.status = status
        }

        /// Reports whether the record can no longer change status.
        func isTerminal() -> Bool {
            switch status {
            case .withdrawn:
                return true
            default:
                break
            }
            return false
        }

        func canMoveTo(_ next: NetworkNoticeStatus) -> Bool {
            switch status {
            case .proposed:
                return next == NetworkNoticeStatus.rejected || next == NetworkNoticeStatus.withdrawn
            case .approved:
                switch next {
                case .rejected, .withdrawn:
                    return true
                default:
                    break
                }
                return false
            case .rejected:
                return next == NetworkNoticeStatus.withdrawn
            default:
                break
            }
            return false
        }

        func moveTo(_ next: NetworkNoticeStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("network notice \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
            version += 1
        }

        func label() -> String {
            return "\("network notice") \(code)"
        }

        func projectedVolume() -> Double {
            return (Double(version) * maximum * 100).rounded() / 100
        }

        func copyValue() -> NetworkNotice {
            return NetworkNotice(
                code: code,
                title: title,
                version: version,
                maximum: maximum,
                contactEmail: contactEmail,
                ownerID: ownerID,
                description: description,
                segment: segment,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(segment)
        }
    }

    /// Starts a network notice in status proposed.
    static func newNetworkNotice(_ code: String, title: String) -> NetworkNotice {
        return NetworkNotice(
            code: code,
            title: title,
            version: 0,
            maximum: 0.0,
            contactEmail: "",
            ownerID: "",
            description: "",
            segment: "",
            status: NetworkNoticeStatus.proposed
        )
    }
}
