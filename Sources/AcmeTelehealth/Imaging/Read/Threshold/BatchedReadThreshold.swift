import AcmePlatform
import Foundation

extension Imaging {
    /// Where a batched read threshold is in its life cycle.
    enum BatchedReadThresholdStatus: String, CaseIterable {
        case requested
        case granted
        case revoked
        case expired
    }

    /// A batched read threshold as the read team keeps it.
    final class BatchedReadThreshold {
        var code: String
        var title: String
        var notes: String
        var rate: Double
        var label: String
        var phone: String
        var limit: Int
        var minimum: Double
        var description: String
        var status: BatchedReadThresholdStatus

        init(code: String, title: String, notes: String, rate: Double, label: String, phone: String, limit: Int, minimum: Double, description: String, status: BatchedReadThresholdStatus) {
            self.code = code
            self.title = title
            self.notes = notes
            self.rate = rate
            self.label = label
            self.phone = phone
            self.limit = limit
            self.minimum = minimum
            self.description = description
            self.status = status
        }

        /// Reports whether the record can no longer change status.
        func isTerminal() -> Bool {
            switch status {
            case .expired:
                return true
            default:
                break
            }
            return false
        }

        func canMoveTo(_ next: BatchedReadThresholdStatus) -> Bool {
            switch status {
            case .requested:
                return next == BatchedReadThresholdStatus.granted
            case .granted:
                switch next {
                case .revoked, .expired:
                    return true
                default:
                    break
                }
                return false
            case .revoked:
                switch next {
                case .expired:
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

        func moveTo(_ next: BatchedReadThresholdStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("batched read threshold \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
        }

        func displayLabel() -> String {
            return "\(code) (\(title))"
        }

        func weightedTotal() -> Double {
            return ((Double(limit) + rate) * 100).rounded() / 100
        }

        func copyValue() -> BatchedReadThreshold {
            return BatchedReadThreshold(
                code: code,
                title: title,
                notes: notes,
                rate: rate,
                label: label,
                phone: phone,
                limit: limit,
                minimum: minimum,
                description: description,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(title)
        }
    }

    /// Starts a batched read threshold in status requested.
    static func newBatchedReadThreshold(_ code: String, title: String) -> BatchedReadThreshold {
        return BatchedReadThreshold(
            code: code,
            title: title,
            notes: "",
            rate: 0.0,
            label: "",
            phone: "",
            limit: 0,
            minimum: 0.0,
            description: "",
            status: BatchedReadThresholdStatus.requested
        )
    }
}
