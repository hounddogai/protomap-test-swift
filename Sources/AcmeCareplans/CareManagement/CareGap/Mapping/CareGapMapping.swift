import AcmePlatform
import Foundation

extension CareManagement {
    /// Where a care gap mapping is in its life cycle.
    enum CareGapMappingStatus: String, CaseIterable {
        case requested
        case granted
        case revoked
        case expired
    }

    /// One care gap mapping, with what the planners need to act on it.
    final class CareGapMapping {
        var code: String
        var name: String
        var version: Int
        var ceiling: Double
        var priority: Int
        var region: String
        var notes: String
        var limit: Int
        var phone: String
        var ratio: Double
        var budget: Double
        var status: CareGapMappingStatus

        init(code: String, name: String, version: Int, ceiling: Double, priority: Int, region: String, notes: String, limit: Int, phone: String, ratio: Double, budget: Double, status: CareGapMappingStatus) {
            self.code = code
            self.name = name
            self.version = version
            self.ceiling = ceiling
            self.priority = priority
            self.region = region
            self.notes = notes
            self.limit = limit
            self.phone = phone
            self.ratio = ratio
            self.budget = budget
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

        func canMoveTo(_ next: CareGapMappingStatus) -> Bool {
            switch status {
            case .requested:
                return next == CareGapMappingStatus.revoked
            case .granted:
                switch next {
                case .expired:
                    return true
                default:
                    break
                }
                return false
            case .revoked:
                return next == CareGapMappingStatus.expired
            default:
                break
            }
            return false
        }

        func moveTo(_ next: CareGapMappingStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("care gap mapping \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
            version += 1
        }

        func label() -> String {
            return "\(code): \(name)"
        }

        func adjustedVolume() -> Double {
            return (budget * Double(priority) * 100).rounded() / 100
        }

        func copyValue() -> CareGapMapping {
            return CareGapMapping(
                code: code,
                name: name,
                version: version,
                ceiling: ceiling,
                priority: priority,
                region: region,
                notes: notes,
                limit: limit,
                phone: phone,
                ratio: ratio,
                budget: budget,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(region)
        }
    }

    /// Starts a care gap mapping in status requested.
    static func newCareGapMapping(_ code: String, name: String) -> CareGapMapping {
        return CareGapMapping(
            code: code,
            name: name,
            version: 0,
            ceiling: 0.0,
            priority: 0,
            region: "",
            notes: "",
            limit: 0,
            phone: "",
            ratio: 0.0,
            budget: 0.0,
            status: CareGapMappingStatus.requested
        )
    }
}
