import AcmePlatform
import Foundation

extension Consent {
    /// Where a revocation adjustment is in its life cycle.
    enum RevocationAdjustmentStatus: String, CaseIterable {
        case created
        case validated
        case published
        case retired
    }

    /// One revocation adjustment, with what the planners need to act on it.
    final class RevocationAdjustment {
        var code: String
        var title: String
        var description: String
        var margin: Double
        var phone: String
        var dosageMg: Double
        var summary: String
        var tags: [String]
        var active: Bool
        var batchSize: Int
        var currency: String
        var status: RevocationAdjustmentStatus

        init(code: String, title: String, description: String, margin: Double, phone: String, dosageMg: Double, summary: String, tags: [String], active: Bool, batchSize: Int, currency: String, status: RevocationAdjustmentStatus) {
            self.code = code
            self.title = title
            self.description = description
            self.margin = margin
            self.phone = phone
            self.dosageMg = dosageMg
            self.summary = summary
            self.tags = tags
            self.active = active
            self.batchSize = batchSize
            self.currency = currency
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

        func canMoveTo(_ next: RevocationAdjustmentStatus) -> Bool {
            switch status {
            case .created:
                return next == RevocationAdjustmentStatus.retired
            case .validated:
                return next == RevocationAdjustmentStatus.published
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

        func moveTo(_ next: RevocationAdjustmentStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("revocation adjustment \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
        }

        func label() -> String {
            return "\(code): \(title)"
        }

        func hasTag(_ tag: String) -> Bool {
            for candidate in tags {
                if Kit.Text.normalize(candidate) == Kit.Text.normalize(tag) {
                    return true
                }
            }
            return false
        }

        func adjustedTotal() -> Double {
            return (Double(batchSize) * margin * 100).rounded() / 100
        }

        func copyValue() -> RevocationAdjustment {
            return RevocationAdjustment(
                code: code,
                title: title,
                description: description,
                margin: margin,
                phone: phone,
                dosageMg: dosageMg,
                summary: summary,
                tags: tags,
                active: active,
                batchSize: batchSize,
                currency: currency,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(title)
        }
    }

    /// Starts a revocation adjustment in status created.
    static func newRevocationAdjustment(_ code: String, title: String) -> RevocationAdjustment {
        return RevocationAdjustment(
            code: code,
            title: title,
            description: "",
            margin: 0.0,
            phone: "",
            dosageMg: 0.0,
            summary: "",
            tags: [],
            active: false,
            batchSize: 0,
            currency: "",
            status: RevocationAdjustmentStatus.created
        )
    }
}
