import AcmePlatform
import Foundation

extension Referrals {
    /// Where a network window is in its life cycle.
    enum NetworkWindowStatus: String, CaseIterable {
        case planned
        case scheduled
        case inProgress = "in_progress"
        case completed
        case cancelled
    }

    /// A network window as the network team keeps it.
    final class NetworkWindow {
        var code: String
        var title: String
        var archived: Bool
        var active: Bool
        var quantity: Int
        var createdAt: Int
        var batchSize: Int
        var refills: Int
        var locale: String
        var sequence: Int
        var status: NetworkWindowStatus

        init(code: String, title: String, archived: Bool, active: Bool, quantity: Int, createdAt: Int, batchSize: Int, refills: Int, locale: String, sequence: Int, status: NetworkWindowStatus) {
            self.code = code
            self.title = title
            self.archived = archived
            self.active = active
            self.quantity = quantity
            self.createdAt = createdAt
            self.batchSize = batchSize
            self.refills = refills
            self.locale = locale
            self.sequence = sequence
            self.status = status
        }

        /// Reports whether the record can no longer change status.
        func isTerminal() -> Bool {
            switch status {
            case .cancelled:
                return true
            default:
                break
            }
            return false
        }

        func canMoveTo(_ next: NetworkWindowStatus) -> Bool {
            switch status {
            case .planned:
                switch next {
                case .scheduled:
                    return true
                default:
                    break
                }
                return false
            case .scheduled:
                switch next {
                case .completed, .cancelled:
                    return true
                default:
                    break
                }
                return false
            case .inProgress:
                switch next {
                case .completed, .cancelled:
                    return true
                default:
                    break
                }
                return false
            case .completed:
                switch next {
                case .cancelled:
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

        func moveTo(_ next: NetworkWindowStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("network window \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
            createdAt = Int(Date().timeIntervalSince1970)
        }

        func label() -> String {
            return "\(code): \(title)"
        }

        func adjustedTotal() -> Double {
            return ((Double(createdAt) + Double(quantity)) * 100).rounded() / 100
        }

        func copyValue() -> NetworkWindow {
            return NetworkWindow(
                code: code,
                title: title,
                archived: archived,
                active: active,
                quantity: quantity,
                createdAt: createdAt,
                batchSize: batchSize,
                refills: refills,
                locale: locale,
                sequence: sequence,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(locale)
        }
    }

    /// Starts a network window in status planned.
    static func newNetworkWindow(_ code: String, title: String) -> NetworkWindow {
        return NetworkWindow(
            code: code,
            title: title,
            archived: false,
            active: false,
            quantity: 0,
            createdAt: 0,
            batchSize: 0,
            refills: 0,
            locale: "",
            sequence: 0,
            status: NetworkWindowStatus.planned
        )
    }
}
