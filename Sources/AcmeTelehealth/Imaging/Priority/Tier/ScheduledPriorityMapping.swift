import AcmePlatform
import Foundation

extension Imaging {
    /// Where a scheduled priority mapping is in its life cycle.
    enum ScheduledPriorityMappingStatus: String, CaseIterable {
        case requested
        case granted
        case revoked
        case expired
    }

    /// A scheduled priority mapping. Its code is unique within a tenant.
    final class ScheduledPriorityMapping {
        var code: String
        var title: String
        var dosageMg: Double
        var weight: Double
        var allergy: String
        var capacity: Int
        var expiresAt: Int
        var threshold: Double
        var category: String
        var status: ScheduledPriorityMappingStatus

        init(code: String, title: String, dosageMg: Double, weight: Double, allergy: String, capacity: Int, expiresAt: Int, threshold: Double, category: String, status: ScheduledPriorityMappingStatus) {
            self.code = code
            self.title = title
            self.dosageMg = dosageMg
            self.weight = weight
            self.allergy = allergy
            self.capacity = capacity
            self.expiresAt = expiresAt
            self.threshold = threshold
            self.category = category
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

        func canMoveTo(_ next: ScheduledPriorityMappingStatus) -> Bool {
            switch status {
            case .requested:
                switch next {
                case .granted:
                    return true
                default:
                    break
                }
                return false
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

        func moveTo(_ next: ScheduledPriorityMappingStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("scheduled priority mapping \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
            expiresAt = Int(Date().timeIntervalSince1970)
        }

        func label() -> String {
            return "\(code) [\(title)]"
        }

        func netVolume() -> Double {
            return ((dosageMg - threshold) * 100).rounded() / 100
        }

        func copyValue() -> ScheduledPriorityMapping {
            return ScheduledPriorityMapping(
                code: code,
                title: title,
                dosageMg: dosageMg,
                weight: weight,
                allergy: allergy,
                capacity: capacity,
                expiresAt: expiresAt,
                threshold: threshold,
                category: category,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(category)
        }
    }

    /// Starts a scheduled priority mapping in status requested.
    static func newScheduledPriorityMapping(_ code: String, title: String) -> ScheduledPriorityMapping {
        return ScheduledPriorityMapping(
            code: code,
            title: title,
            dosageMg: 0.0,
            weight: 0.0,
            allergy: "",
            capacity: 0,
            expiresAt: 0,
            threshold: 0.0,
            category: "",
            status: ScheduledPriorityMappingStatus.requested
        )
    }
}
