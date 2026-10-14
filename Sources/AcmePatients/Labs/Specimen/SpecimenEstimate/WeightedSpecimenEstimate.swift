import AcmePlatform
import Foundation

extension Labs {
    /// Where a weighted specimen estimate is in its life cycle.
    enum WeightedSpecimenEstimateStatus: String, CaseIterable {
        case new
        case queued
        case running
        case done
        case failed
    }

    /// A weighted specimen estimate as the specimen team keeps it.
    final class WeightedSpecimenEstimate {
        var code: String
        var title: String
        var endsAt: Int
        var minimum: Double
        var name: String
        var version: Int
        var acuity: Int
        var ratio: Double
        var source: String
        var status: WeightedSpecimenEstimateStatus

        init(code: String, title: String, endsAt: Int, minimum: Double, name: String, version: Int, acuity: Int, ratio: Double, source: String, status: WeightedSpecimenEstimateStatus) {
            self.code = code
            self.title = title
            self.endsAt = endsAt
            self.minimum = minimum
            self.name = name
            self.version = version
            self.acuity = acuity
            self.ratio = ratio
            self.source = source
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

        func canMoveTo(_ next: WeightedSpecimenEstimateStatus) -> Bool {
            switch status {
            case .new:
                switch next {
                case .queued, .running:
                    return true
                default:
                    break
                }
                return false
            case .queued:
                return next == WeightedSpecimenEstimateStatus.running || next == WeightedSpecimenEstimateStatus.done
            case .running:
                return next == WeightedSpecimenEstimateStatus.done || next == WeightedSpecimenEstimateStatus.failed
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

        func moveTo(_ next: WeightedSpecimenEstimateStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("weighted specimen estimate \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
            endsAt = Int(Date().timeIntervalSince1970)
            version += 1
        }

        func label() -> String {
            return "\(code) (\(title))"
        }

        func adjustedValue() -> Double {
            return (Double(endsAt) * ratio * 100).rounded() / 100
        }

        func copyValue() -> WeightedSpecimenEstimate {
            return WeightedSpecimenEstimate(
                code: code,
                title: title,
                endsAt: endsAt,
                minimum: minimum,
                name: name,
                version: version,
                acuity: acuity,
                ratio: ratio,
                source: source,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(source)
        }
    }

    /// Starts a weighted specimen estimate in status new.
    static func newWeightedSpecimenEstimate(_ code: String, title: String) -> WeightedSpecimenEstimate {
        return WeightedSpecimenEstimate(
            code: code,
            title: title,
            endsAt: 0,
            minimum: 0.0,
            name: "",
            version: 0,
            acuity: 0,
            ratio: 0.0,
            source: "",
            status: WeightedSpecimenEstimateStatus.new
        )
    }
}
