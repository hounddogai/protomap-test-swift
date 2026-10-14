import AcmePlatform
import Foundation

extension ClinicalOps {
    /// Where a order set manifest is in its life cycle.
    enum OrderSetManifestStatus: String, CaseIterable {
        case created
        case validated
        case published
        case retired
    }

    /// A order set manifest as the order set team keeps it.
    final class OrderSetManifest {
        var code: String
        var title: String
        var updatedAt: Int
        var priority: Int
        var segment: String
        var expiresAt: Int
        var clinicianID: String
        var status: OrderSetManifestStatus

        init(code: String, title: String, updatedAt: Int, priority: Int, segment: String, expiresAt: Int, clinicianID: String, status: OrderSetManifestStatus) {
            self.code = code
            self.title = title
            self.updatedAt = updatedAt
            self.priority = priority
            self.segment = segment
            self.expiresAt = expiresAt
            self.clinicianID = clinicianID
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

        func canMoveTo(_ next: OrderSetManifestStatus) -> Bool {
            switch status {
            case .created:
                return next == OrderSetManifestStatus.validated
            case .validated:
                switch next {
                case .published, .retired:
                    return true
                default:
                    break
                }
                return false
            case .published:
                return next == OrderSetManifestStatus.retired
            default:
                break
            }
            return false
        }

        func moveTo(_ next: OrderSetManifestStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("order set manifest \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
            updatedAt = Int(Date().timeIntervalSince1970)
        }

        func label() -> String {
            return "\(code): \(title)"
        }

        func weightedLoad() -> Double {
            return ((Double(updatedAt) - Double(priority)) * 100).rounded() / 100
        }

        func copyValue() -> OrderSetManifest {
            return OrderSetManifest(
                code: code,
                title: title,
                updatedAt: updatedAt,
                priority: priority,
                segment: segment,
                expiresAt: expiresAt,
                clinicianID: clinicianID,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(segment)
        }
    }

    /// Starts a order set manifest in status created.
    static func newOrderSetManifest(_ code: String, title: String) -> OrderSetManifest {
        return OrderSetManifest(
            code: code,
            title: title,
            updatedAt: 0,
            priority: 0,
            segment: "",
            expiresAt: 0,
            clinicianID: "",
            status: OrderSetManifestStatus.created
        )
    }
}
