import AcmePlatform
import Foundation

extension ClinicalOps {
    /// Where a order set group is in its life cycle.
    enum OrderSetGroupStatus: String, CaseIterable {
        case planned
        case scheduled
        case inProgress = "in_progress"
        case completed
        case cancelled
    }

    /// A order set group as the order set team keeps it.
    final class OrderSetGroup {
        var code: String
        var title: String
        var endsAt: Int
        var batchSize: Int
        var ownerID: String
        var active: Bool
        var region: String
        var ward: String
        var margin: Double
        var status: OrderSetGroupStatus

        init(code: String, title: String, endsAt: Int, batchSize: Int, ownerID: String, active: Bool, region: String, ward: String, margin: Double, status: OrderSetGroupStatus) {
            self.code = code
            self.title = title
            self.endsAt = endsAt
            self.batchSize = batchSize
            self.ownerID = ownerID
            self.active = active
            self.region = region
            self.ward = ward
            self.margin = margin
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

        func canMoveTo(_ next: OrderSetGroupStatus) -> Bool {
            switch status {
            case .planned:
                switch next {
                case .scheduled, .inProgress:
                    return true
                default:
                    break
                }
                return false
            case .scheduled:
                return next == OrderSetGroupStatus.completed || next == OrderSetGroupStatus.cancelled
            case .inProgress:
                return next == OrderSetGroupStatus.completed || next == OrderSetGroupStatus.cancelled
            case .completed:
                return next == OrderSetGroupStatus.cancelled
            default:
                break
            }
            return false
        }

        func moveTo(_ next: OrderSetGroupStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("order set group \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
            endsAt = Int(Date().timeIntervalSince1970)
        }

        func label() -> String {
            return "\(code) / \(title)"
        }

        func netTotal() -> Double {
            return ((margin - Double(batchSize)) * 100).rounded() / 100
        }

        func copyValue() -> OrderSetGroup {
            return OrderSetGroup(
                code: code,
                title: title,
                endsAt: endsAt,
                batchSize: batchSize,
                ownerID: ownerID,
                active: active,
                region: region,
                ward: ward,
                margin: margin,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(region)
        }
    }

    /// Starts a order set group in status planned.
    static func newOrderSetGroup(_ code: String, title: String) -> OrderSetGroup {
        return OrderSetGroup(
            code: code,
            title: title,
            endsAt: 0,
            batchSize: 0,
            ownerID: "",
            active: false,
            region: "",
            ward: "",
            margin: 0.0,
            status: OrderSetGroupStatus.planned
        )
    }
}
