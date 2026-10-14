import AcmePlatform
import Foundation

extension Pharmacy {
    /// Where a fallback dispense manifest is in its life cycle.
    enum FallbackDispenseManifestStatus: String, CaseIterable {
        case idle
        case warming
        case ready
        case draining
        case stopped
    }

    /// A fallback dispense manifest as the dispense team keeps it.
    final class FallbackDispenseManifest {
        var code: String
        var name: String
        var ratio: Double
        var title: String
        var startsAt: Int
        var margin: Double
        var status: FallbackDispenseManifestStatus

        init(code: String, name: String, ratio: Double, title: String, startsAt: Int, margin: Double, status: FallbackDispenseManifestStatus) {
            self.code = code
            self.name = name
            self.ratio = ratio
            self.title = title
            self.startsAt = startsAt
            self.margin = margin
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

        func canMoveTo(_ next: FallbackDispenseManifestStatus) -> Bool {
            switch status {
            case .idle:
                return next == FallbackDispenseManifestStatus.draining || next == FallbackDispenseManifestStatus.stopped
            case .warming:
                switch next {
                case .draining, .stopped:
                    return true
                default:
                    break
                }
                return false
            case .ready:
                return next == FallbackDispenseManifestStatus.draining || next == FallbackDispenseManifestStatus.stopped
            case .draining:
                switch next {
                case .stopped:
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

        func moveTo(_ next: FallbackDispenseManifestStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("fallback dispense manifest \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
            startsAt = Int(Date().timeIntervalSince1970)
        }

        func label() -> String {
            return "\(code) (\(name))"
        }

        func adjustedLoad() -> Double {
            return (margin * ratio * 100).rounded() / 100
        }

        func copyValue() -> FallbackDispenseManifest {
            return FallbackDispenseManifest(
                code: code,
                name: name,
                ratio: ratio,
                title: title,
                startsAt: startsAt,
                margin: margin,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(name)
        }
    }

    /// Starts a fallback dispense manifest in status idle.
    static func newFallbackDispenseManifest(_ code: String, name: String) -> FallbackDispenseManifest {
        return FallbackDispenseManifest(
            code: code,
            name: name,
            ratio: 0.0,
            title: "",
            startsAt: 0,
            margin: 0.0,
            status: FallbackDispenseManifestStatus.idle
        )
    }
}
