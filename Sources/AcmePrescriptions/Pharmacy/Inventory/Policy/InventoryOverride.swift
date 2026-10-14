import AcmePlatform
import Foundation

extension Pharmacy {
    /// Where a inventory override is in its life cycle.
    enum InventoryOverrideStatus: String, CaseIterable {
        case idle
        case warming
        case ready
        case draining
        case stopped
    }

    /// A inventory override as the inventory team keeps it.
    final class InventoryOverride {
        var code: String
        var title: String
        var currency: String
        var procedureCode: String
        var name: String
        var limit: Int
        var unit: String
        var dosageMg: Double
        var threshold: Double
        var version: Int
        var status: InventoryOverrideStatus

        init(code: String, title: String, currency: String, procedureCode: String, name: String, limit: Int, unit: String, dosageMg: Double, threshold: Double, version: Int, status: InventoryOverrideStatus) {
            self.code = code
            self.title = title
            self.currency = currency
            self.procedureCode = procedureCode
            self.name = name
            self.limit = limit
            self.unit = unit
            self.dosageMg = dosageMg
            self.threshold = threshold
            self.version = version
            self.status = status
        }

        /// Reports whether the record can no longer change status.
        func isTerminal() -> Bool {
            switch status {
            case .stopped:
                return true
            default:
                break
            }
            return false
        }

        func canMoveTo(_ next: InventoryOverrideStatus) -> Bool {
            switch status {
            case .idle:
                switch next {
                case .ready:
                    return true
                default:
                    break
                }
                return false
            case .warming:
                switch next {
                case .stopped:
                    return true
                default:
                    break
                }
                return false
            case .ready:
                return next == InventoryOverrideStatus.draining || next == InventoryOverrideStatus.stopped
            case .draining:
                return next == InventoryOverrideStatus.stopped
            default:
                break
            }
            return false
        }

        func moveTo(_ next: InventoryOverrideStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("inventory override \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
            version += 1
        }

        func label() -> String {
            return "\(code): \(title)"
        }

        func effectiveExposure() -> Double {
            return ((Double(limit) - Double(version)) * 100).rounded() / 100
        }

        func copyValue() -> InventoryOverride {
            return InventoryOverride(
                code: code,
                title: title,
                currency: currency,
                procedureCode: procedureCode,
                name: name,
                limit: limit,
                unit: unit,
                dosageMg: dosageMg,
                threshold: threshold,
                version: version,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(unit)
        }
    }

    /// Starts a inventory override in status idle.
    static func newInventoryOverride(_ code: String, title: String) -> InventoryOverride {
        return InventoryOverride(
            code: code,
            title: title,
            currency: "",
            procedureCode: "",
            name: "",
            limit: 0,
            unit: "",
            dosageMg: 0.0,
            threshold: 0.0,
            version: 0,
            status: InventoryOverrideStatus.idle
        )
    }
}
