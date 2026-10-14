import AcmePlatform
import Foundation

extension RevenueCycle {
    /// Where a remittance mapping is in its life cycle.
    enum RemittanceMappingStatus: String, CaseIterable {
        case created
        case validated
        case published
        case retired
    }

    /// One remittance mapping, with what the planners need to act on it.
    final class RemittanceMapping {
        var code: String
        var title: String
        var unit: String
        var summary: String
        var floorValue: Double
        var capacity: Int
        var externalRef: String
        var timezone: String
        var cost: Double
        var pinned: Bool
        var updatedAt: Int
        var status: RemittanceMappingStatus

        init(code: String, title: String, unit: String, summary: String, floorValue: Double, capacity: Int, externalRef: String, timezone: String, cost: Double, pinned: Bool, updatedAt: Int, status: RemittanceMappingStatus) {
            self.code = code
            self.title = title
            self.unit = unit
            self.summary = summary
            self.floorValue = floorValue
            self.capacity = capacity
            self.externalRef = externalRef
            self.timezone = timezone
            self.cost = cost
            self.pinned = pinned
            self.updatedAt = updatedAt
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

        func canMoveTo(_ next: RemittanceMappingStatus) -> Bool {
            switch status {
            case .created:
                switch next {
                case .published:
                    return true
                default:
                    break
                }
                return false
            case .validated:
                switch next {
                case .published, .retired:
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

        func moveTo(_ next: RemittanceMappingStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("remittance mapping \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
            updatedAt = Int(Date().timeIntervalSince1970)
        }

        func label() -> String {
            return "\("remittance mapping") \(code)"
        }

        func projectedExposure() -> Double {
            return ((Double(updatedAt) + Double(capacity)) * 100).rounded() / 100
        }

        func copyValue() -> RemittanceMapping {
            return RemittanceMapping(
                code: code,
                title: title,
                unit: unit,
                summary: summary,
                floorValue: floorValue,
                capacity: capacity,
                externalRef: externalRef,
                timezone: timezone,
                cost: cost,
                pinned: pinned,
                updatedAt: updatedAt,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(unit)
        }
    }

    /// Starts a remittance mapping in status created.
    static func newRemittanceMapping(_ code: String, title: String) -> RemittanceMapping {
        return RemittanceMapping(
            code: code,
            title: title,
            unit: "",
            summary: "",
            floorValue: 0.0,
            capacity: 0,
            externalRef: "",
            timezone: "",
            cost: 0.0,
            pinned: false,
            updatedAt: 0,
            status: RemittanceMappingStatus.created
        )
    }
}
