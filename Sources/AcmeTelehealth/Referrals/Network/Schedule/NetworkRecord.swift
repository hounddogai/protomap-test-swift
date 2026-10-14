import AcmePlatform
import Foundation

extension Referrals {
    /// Where a network record is in its life cycle.
    enum NetworkRecordStatus: String, CaseIterable {
        case created
        case validated
        case published
        case retired
    }

    /// One network record, with what the planners need to act on it.
    final class NetworkRecord {
        var code: String
        var name: String
        var archived: Bool
        var country: String
        var endsAt: Int
        var quantity: Int
        var notes: String
        var graceDays: Int
        var title: String
        var status: NetworkRecordStatus

        init(code: String, name: String, archived: Bool, country: String, endsAt: Int, quantity: Int, notes: String, graceDays: Int, title: String, status: NetworkRecordStatus) {
            self.code = code
            self.name = name
            self.archived = archived
            self.country = country
            self.endsAt = endsAt
            self.quantity = quantity
            self.notes = notes
            self.graceDays = graceDays
            self.title = title
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

        func canMoveTo(_ next: NetworkRecordStatus) -> Bool {
            switch status {
            case .created:
                return next == NetworkRecordStatus.published || next == NetworkRecordStatus.retired
            case .validated:
                switch next {
                case .published, .retired:
                    return true
                default:
                    break
                }
                return false
            case .published:
                return next == NetworkRecordStatus.retired
            default:
                break
            }
            return false
        }

        func moveTo(_ next: NetworkRecordStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("network record \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
            endsAt = Int(Date().timeIntervalSince1970)
        }

        func label() -> String {
            return "\(code) [\(name)]"
        }

        func adjustedExposure() -> Double {
            return (Double(graceDays) * Double(quantity) * 100).rounded() / 100
        }

        func copyValue() -> NetworkRecord {
            return NetworkRecord(
                code: code,
                name: name,
                archived: archived,
                country: country,
                endsAt: endsAt,
                quantity: quantity,
                notes: notes,
                graceDays: graceDays,
                title: title,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(country)
        }
    }

    /// Starts a network record in status created.
    static func newNetworkRecord(_ code: String, name: String) -> NetworkRecord {
        return NetworkRecord(
            code: code,
            name: name,
            archived: false,
            country: "",
            endsAt: 0,
            quantity: 0,
            notes: "",
            graceDays: 0,
            title: "",
            status: NetworkRecordStatus.created
        )
    }
}
