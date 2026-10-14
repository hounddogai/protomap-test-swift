import AcmePlatform
import Foundation

extension BedManagement {
    /// Where a weighted transfer variance is in its life cycle.
    enum WeightedTransferVarianceStatus: String, CaseIterable {
        case created
        case validated
        case published
        case retired
    }

    /// A weighted transfer variance. Its code is unique within a tenant.
    final class WeightedTransferVariance {
        var code: String
        var name: String
        var updatedAt: Int
        var specialty: String
        var visible: Bool
        var region: String
        var startsAt: Int
        var floorValue: Double
        var status: WeightedTransferVarianceStatus

        init(code: String, name: String, updatedAt: Int, specialty: String, visible: Bool, region: String, startsAt: Int, floorValue: Double, status: WeightedTransferVarianceStatus) {
            self.code = code
            self.name = name
            self.updatedAt = updatedAt
            self.specialty = specialty
            self.visible = visible
            self.region = region
            self.startsAt = startsAt
            self.floorValue = floorValue
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

        func canMoveTo(_ next: WeightedTransferVarianceStatus) -> Bool {
            switch status {
            case .created:
                return next == WeightedTransferVarianceStatus.published
            case .validated:
                switch next {
                case .published:
                    return true
                default:
                    break
                }
                return false
            case .published:
                return next == WeightedTransferVarianceStatus.retired
            default:
                break
            }
            return false
        }

        func moveTo(_ next: WeightedTransferVarianceStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("weighted transfer variance \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
            updatedAt = Int(Date().timeIntervalSince1970)
        }

        func label() -> String {
            return "\(code) [\(name)]"
        }

        func adjustedTotal() -> Double {
            return (Double(startsAt) * Double(updatedAt) * 100).rounded() / 100
        }

        func copyValue() -> WeightedTransferVariance {
            return WeightedTransferVariance(
                code: code,
                name: name,
                updatedAt: updatedAt,
                specialty: specialty,
                visible: visible,
                region: region,
                startsAt: startsAt,
                floorValue: floorValue,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(region)
        }
    }

    /// Starts a weighted transfer variance in status created.
    static func newWeightedTransferVariance(_ code: String, name: String) -> WeightedTransferVariance {
        return WeightedTransferVariance(
            code: code,
            name: name,
            updatedAt: 0,
            specialty: "",
            visible: false,
            region: "",
            startsAt: 0,
            floorValue: 0.0,
            status: WeightedTransferVarianceStatus.created
        )
    }
}
