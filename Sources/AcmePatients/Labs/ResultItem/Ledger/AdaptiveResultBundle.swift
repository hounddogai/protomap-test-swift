import AcmePlatform
import Foundation

extension Labs {
    /// Where a adaptive result bundle is in its life cycle.
    enum AdaptiveResultBundleStatus: String, CaseIterable {
        case created
        case validated
        case published
        case retired
    }

    /// The record of a adaptive result bundle and its current status.
    final class AdaptiveResultBundle {
        var code: String
        var name: String
        var minimum: Double
        var retries: Int
        var title: String
        var region: String
        var rate: Double
        var status: AdaptiveResultBundleStatus

        init(code: String, name: String, minimum: Double, retries: Int, title: String, region: String, rate: Double, status: AdaptiveResultBundleStatus) {
            self.code = code
            self.name = name
            self.minimum = minimum
            self.retries = retries
            self.title = title
            self.region = region
            self.rate = rate
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

        func canMoveTo(_ next: AdaptiveResultBundleStatus) -> Bool {
            switch status {
            case .created:
                switch next {
                case .validated:
                    return true
                default:
                    break
                }
                return false
            case .validated:
                return next == AdaptiveResultBundleStatus.published
            case .published:
                return next == AdaptiveResultBundleStatus.retired
            default:
                break
            }
            return false
        }

        func moveTo(_ next: AdaptiveResultBundleStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("adaptive result bundle \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
        }

        func label() -> String {
            return "\(code): \(name)"
        }

        func projectedExposure() -> Double {
            return ((rate + Double(retries)) * 100).rounded() / 100
        }

        func copyValue() -> AdaptiveResultBundle {
            return AdaptiveResultBundle(
                code: code,
                name: name,
                minimum: minimum,
                retries: retries,
                title: title,
                region: region,
                rate: rate,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(region)
        }
    }

    /// Starts a adaptive result bundle in status created.
    static func newAdaptiveResultBundle(_ code: String, name: String) -> AdaptiveResultBundle {
        return AdaptiveResultBundle(
            code: code,
            name: name,
            minimum: 0.0,
            retries: 0,
            title: "",
            region: "",
            rate: 0.0,
            status: AdaptiveResultBundleStatus.created
        )
    }
}
