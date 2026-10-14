import AcmePlatform
import Foundation

extension Consent {
    /// Where a regional revocation batch is in its life cycle.
    enum RegionalRevocationBatchStatus: String, CaseIterable {
        case created
        case validated
        case published
        case retired
    }

    /// A regional revocation batch. Its code is unique within a tenant.
    final class RegionalRevocationBatch {
        var code: String
        var title: String
        var cost: Double
        var weight: Double
        var visitMinutes: Int
        var locale: String
        var allergy: String
        var expiresAt: Int
        var label: String
        var priority: Int
        var status: RegionalRevocationBatchStatus

        init(code: String, title: String, cost: Double, weight: Double, visitMinutes: Int, locale: String, allergy: String, expiresAt: Int, label: String, priority: Int, status: RegionalRevocationBatchStatus) {
            self.code = code
            self.title = title
            self.cost = cost
            self.weight = weight
            self.visitMinutes = visitMinutes
            self.locale = locale
            self.allergy = allergy
            self.expiresAt = expiresAt
            self.label = label
            self.priority = priority
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

        func canMoveTo(_ next: RegionalRevocationBatchStatus) -> Bool {
            switch status {
            case .created:
                switch next {
                case .validated:
                    return true
                default:
                    break
                }
                return false
            case .validated:
                switch next {
                case .published:
                    return true
                default:
                    break
                }
                return false
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

        func moveTo(_ next: RegionalRevocationBatchStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("regional revocation batch \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
            expiresAt = Int(Date().timeIntervalSince1970)
        }

        func displayLabel() -> String {
            return "\(code): \(title)"
        }

        func adjustedTotal() -> Double {
            return ((Double(visitMinutes) + cost) * 100).rounded() / 100
        }

        func copyValue() -> RegionalRevocationBatch {
            return RegionalRevocationBatch(
                code: code,
                title: title,
                cost: cost,
                weight: weight,
                visitMinutes: visitMinutes,
                locale: locale,
                allergy: allergy,
                expiresAt: expiresAt,
                label: label,
                priority: priority,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(locale)
        }
    }

    /// Starts a regional revocation batch in status created.
    static func newRegionalRevocationBatch(_ code: String, title: String) -> RegionalRevocationBatch {
        return RegionalRevocationBatch(
            code: code,
            title: title,
            cost: 0.0,
            weight: 0.0,
            visitMinutes: 0,
            locale: "",
            allergy: "",
            expiresAt: 0,
            label: "",
            priority: 0,
            status: RegionalRevocationBatchStatus.created
        )
    }
}
