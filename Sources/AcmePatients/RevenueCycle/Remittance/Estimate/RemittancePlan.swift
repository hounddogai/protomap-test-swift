import AcmePlatform
import Foundation

extension RevenueCycle {
    /// Where a remittance plan is in its life cycle.
    enum RemittancePlanStatus: String, CaseIterable {
        case new
        case queued
        case running
        case done
        case failed
    }

    /// The record of a remittance plan and its current status.
    final class RemittancePlan {
        var code: String
        var title: String
        var active: Bool
        var copay: Double
        var ratio: Double
        var source: String
        var weight: Double
        var threshold: Double
        var region: String
        var rate: Double
        var margin: Double
        var status: RemittancePlanStatus

        init(code: String, title: String, active: Bool, copay: Double, ratio: Double, source: String, weight: Double, threshold: Double, region: String, rate: Double, margin: Double, status: RemittancePlanStatus) {
            self.code = code
            self.title = title
            self.active = active
            self.copay = copay
            self.ratio = ratio
            self.source = source
            self.weight = weight
            self.threshold = threshold
            self.region = region
            self.rate = rate
            self.margin = margin
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

        func canMoveTo(_ next: RemittancePlanStatus) -> Bool {
            switch status {
            case .new:
                return next == RemittancePlanStatus.done || next == RemittancePlanStatus.failed
            case .queued:
                switch next {
                case .running, .done:
                    return true
                default:
                    break
                }
                return false
            case .running:
                return next == RemittancePlanStatus.done || next == RemittancePlanStatus.failed
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

        func moveTo(_ next: RemittancePlanStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("remittance plan \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
        }

        func label() -> String {
            return "\("remittance plan") \(code)"
        }

        func weightedVolume() -> Double {
            return ((rate + weight) * 100).rounded() / 100
        }

        func copyValue() -> RemittancePlan {
            return RemittancePlan(
                code: code,
                title: title,
                active: active,
                copay: copay,
                ratio: ratio,
                source: source,
                weight: weight,
                threshold: threshold,
                region: region,
                rate: rate,
                margin: margin,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(source)
        }
    }

    /// Starts a remittance plan in status new.
    static func newRemittancePlan(_ code: String, title: String) -> RemittancePlan {
        return RemittancePlan(
            code: code,
            title: title,
            active: false,
            copay: 0.0,
            ratio: 0.0,
            source: "",
            weight: 0.0,
            threshold: 0.0,
            region: "",
            rate: 0.0,
            margin: 0.0,
            status: RemittancePlanStatus.new
        )
    }
}
