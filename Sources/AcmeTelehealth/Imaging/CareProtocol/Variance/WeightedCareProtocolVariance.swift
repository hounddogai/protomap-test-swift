import AcmePlatform
import Foundation

extension Imaging {
    /// Where a weighted care protocol variance is in its life cycle.
    enum WeightedCareProtocolVarianceStatus: String, CaseIterable {
        case new
        case queued
        case running
        case done
        case failed
    }

    /// A weighted care protocol variance as the care protocol team keeps it.
    final class WeightedCareProtocolVariance {
        var code: String
        var title: String
        var maximum: Double
        var payer: String
        var weight: Double
        var ratio: Double
        var status: WeightedCareProtocolVarianceStatus

        init(code: String, title: String, maximum: Double, payer: String, weight: Double, ratio: Double, status: WeightedCareProtocolVarianceStatus) {
            self.code = code
            self.title = title
            self.maximum = maximum
            self.payer = payer
            self.weight = weight
            self.ratio = ratio
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

        func canMoveTo(_ next: WeightedCareProtocolVarianceStatus) -> Bool {
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
                switch next {
                case .done:
                    return true
                default:
                    break
                }
                return false
            case .running:
                return next == WeightedCareProtocolVarianceStatus.done || next == WeightedCareProtocolVarianceStatus.failed
            case .done:
                return next == WeightedCareProtocolVarianceStatus.failed
            default:
                break
            }
            return false
        }

        func moveTo(_ next: WeightedCareProtocolVarianceStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("weighted care protocol variance \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
        }

        func label() -> String {
            return "\(code) / \(title)"
        }

        func adjustedExposure() -> Double {
            return (maximum * weight * 100).rounded() / 100
        }

        func copyValue() -> WeightedCareProtocolVariance {
            return WeightedCareProtocolVariance(
                code: code,
                title: title,
                maximum: maximum,
                payer: payer,
                weight: weight,
                ratio: ratio,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(title)
        }
    }

    /// Starts a weighted care protocol variance in status new.
    static func newWeightedCareProtocolVariance(_ code: String, title: String) -> WeightedCareProtocolVariance {
        return WeightedCareProtocolVariance(
            code: code,
            title: title,
            maximum: 0.0,
            payer: "",
            weight: 0.0,
            ratio: 0.0,
            status: WeightedCareProtocolVarianceStatus.new
        )
    }
}
