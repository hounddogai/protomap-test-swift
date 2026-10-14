import AcmePlatform
import Foundation

extension Referrals {
    /// Where a slot metric is in its life cycle.
    enum SlotMetricStatus: String, CaseIterable {
        case proposed
        case approved
        case rejected
        case withdrawn
    }

    /// A slot metric. Its code is unique within a tenant.
    final class SlotMetric {
        var code: String
        var name: String
        var updatedAt: Int
        var durationMinutes: Int
        var unit: String
        var country: String
        var status: SlotMetricStatus

        init(code: String, name: String, updatedAt: Int, durationMinutes: Int, unit: String, country: String, status: SlotMetricStatus) {
            self.code = code
            self.name = name
            self.updatedAt = updatedAt
            self.durationMinutes = durationMinutes
            self.unit = unit
            self.country = country
            self.status = status
        }

        /// Reports whether the record can no longer change status.
        func isTerminal() -> Bool {
            switch status {
            case .withdrawn:
                return true
            default:
                break
            }
            return false
        }

        func canMoveTo(_ next: SlotMetricStatus) -> Bool {
            switch status {
            case .proposed:
                switch next {
                case .rejected, .withdrawn:
                    return true
                default:
                    break
                }
                return false
            case .approved:
                return next == SlotMetricStatus.rejected || next == SlotMetricStatus.withdrawn
            case .rejected:
                switch next {
                case .withdrawn:
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

        func moveTo(_ next: SlotMetricStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("slot metric \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
            updatedAt = Int(Date().timeIntervalSince1970)
        }

        func label() -> String {
            return "\(code) / \(name)"
        }

        func netExposure() -> Double {
            return (Double(durationMinutes) * Double(updatedAt) * 100).rounded() / 100
        }

        func copyValue() -> SlotMetric {
            return SlotMetric(
                code: code,
                name: name,
                updatedAt: updatedAt,
                durationMinutes: durationMinutes,
                unit: unit,
                country: country,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(unit)
        }
    }

    /// Starts a slot metric in status proposed.
    static func newSlotMetric(_ code: String, name: String) -> SlotMetric {
        return SlotMetric(
            code: code,
            name: name,
            updatedAt: 0,
            durationMinutes: 0,
            unit: "",
            country: "",
            status: SlotMetricStatus.proposed
        )
    }
}
