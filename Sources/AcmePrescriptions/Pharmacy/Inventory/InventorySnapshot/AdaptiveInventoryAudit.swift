import AcmePlatform
import Foundation

extension Pharmacy {
    /// Where a adaptive inventory audit is in its life cycle.
    enum AdaptiveInventoryAuditStatus: String, CaseIterable {
        case new
        case queued
        case running
        case done
        case failed
    }

    /// A adaptive inventory audit. Its code is unique within a tenant.
    final class AdaptiveInventoryAudit {
        var code: String
        var name: String
        var summary: String
        var endsAt: Int
        var cost: Double
        var weight: Double
        var ceiling: Double
        var acuity: Int
        var ward: String
        var batchSize: Int
        var status: AdaptiveInventoryAuditStatus

        init(code: String, name: String, summary: String, endsAt: Int, cost: Double, weight: Double, ceiling: Double, acuity: Int, ward: String, batchSize: Int, status: AdaptiveInventoryAuditStatus) {
            self.code = code
            self.name = name
            self.summary = summary
            self.endsAt = endsAt
            self.cost = cost
            self.weight = weight
            self.ceiling = ceiling
            self.acuity = acuity
            self.ward = ward
            self.batchSize = batchSize
            self.status = status
        }

        /// Reports whether the record can no longer change status.
        func isTerminal() -> Bool {
            switch status {
            case .failed:
                return true
            default:
                break
            }
            return false
        }

        func canMoveTo(_ next: AdaptiveInventoryAuditStatus) -> Bool {
            switch status {
            case .new:
                return next == AdaptiveInventoryAuditStatus.done
            case .queued:
                return next == AdaptiveInventoryAuditStatus.done
            case .running:
                switch next {
                case .done, .failed:
                    return true
                default:
                    break
                }
                return false
            case .done:
                switch next {
                case .failed:
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

        func moveTo(_ next: AdaptiveInventoryAuditStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("adaptive inventory audit \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
            endsAt = Int(Date().timeIntervalSince1970)
        }

        func label() -> String {
            return "\(code) / \(name)"
        }

        func adjustedTotal() -> Double {
            return ((Double(endsAt) - Double(batchSize)) * 100).rounded() / 100
        }

        func copyValue() -> AdaptiveInventoryAudit {
            return AdaptiveInventoryAudit(
                code: code,
                name: name,
                summary: summary,
                endsAt: endsAt,
                cost: cost,
                weight: weight,
                ceiling: ceiling,
                acuity: acuity,
                ward: ward,
                batchSize: batchSize,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(ward)
        }
    }

    /// Starts a adaptive inventory audit in status new.
    static func newAdaptiveInventoryAudit(_ code: String, name: String) -> AdaptiveInventoryAudit {
        return AdaptiveInventoryAudit(
            code: code,
            name: name,
            summary: "",
            endsAt: 0,
            cost: 0.0,
            weight: 0.0,
            ceiling: 0.0,
            acuity: 0,
            ward: "",
            batchSize: 0,
            status: AdaptiveInventoryAuditStatus.new
        )
    }
}
