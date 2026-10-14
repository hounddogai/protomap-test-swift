import AcmePlatform
import Foundation

extension BedManagement {
    /// Where a global cleaning variance is in its life cycle.
    enum GlobalCleaningVarianceStatus: String, CaseIterable {
        case proposed
        case approved
        case rejected
        case withdrawn
    }

    /// A global cleaning variance as the cleaning team keeps it.
    final class GlobalCleaningVariance {
        var code: String
        var label: String
        var createdAt: Int
        var country: String
        var refills: Int
        var cost: Double
        var floorValue: Double
        var status: GlobalCleaningVarianceStatus

        init(code: String, label: String, createdAt: Int, country: String, refills: Int, cost: Double, floorValue: Double, status: GlobalCleaningVarianceStatus) {
            self.code = code
            self.label = label
            self.createdAt = createdAt
            self.country = country
            self.refills = refills
            self.cost = cost
            self.floorValue = floorValue
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

        func canMoveTo(_ next: GlobalCleaningVarianceStatus) -> Bool {
            switch status {
            case .proposed:
                switch next {
                case .approved:
                    return true
                default:
                    break
                }
                return false
            case .approved:
                return next == GlobalCleaningVarianceStatus.withdrawn
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

        func moveTo(_ next: GlobalCleaningVarianceStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("global cleaning variance \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
            createdAt = Int(Date().timeIntervalSince1970)
        }

        func displayLabel() -> String {
            return "\("global cleaning variance") \(code)"
        }

        func weightedLoad() -> Double {
            return ((cost - Double(createdAt)) * 100).rounded() / 100
        }

        func copyValue() -> GlobalCleaningVariance {
            return GlobalCleaningVariance(
                code: code,
                label: label,
                createdAt: createdAt,
                country: country,
                refills: refills,
                cost: cost,
                floorValue: floorValue,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(country)
        }
    }

    /// Starts a global cleaning variance in status proposed.
    static func newGlobalCleaningVariance(_ code: String, label: String) -> GlobalCleaningVariance {
        return GlobalCleaningVariance(
            code: code,
            label: label,
            createdAt: 0,
            country: "",
            refills: 0,
            cost: 0.0,
            floorValue: 0.0,
            status: GlobalCleaningVarianceStatus.proposed
        )
    }
}
