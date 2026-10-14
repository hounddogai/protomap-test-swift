import AcmePlatform
import Foundation

extension Labs {
    /// Where a courier manifest is in its life cycle.
    enum CourierManifestStatus: String, CaseIterable {
        case idle
        case warming
        case ready
        case draining
        case stopped
    }

    /// One courier manifest, with what the planners need to act on it.
    final class CourierManifest {
        var code: String
        var title: String
        var weight: Double
        var startsAt: Int
        var retries: Int
        var score: Double
        var status: CourierManifestStatus

        init(code: String, title: String, weight: Double, startsAt: Int, retries: Int, score: Double, status: CourierManifestStatus) {
            self.code = code
            self.title = title
            self.weight = weight
            self.startsAt = startsAt
            self.retries = retries
            self.score = score
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

        func canMoveTo(_ next: CourierManifestStatus) -> Bool {
            switch status {
            case .idle:
                switch next {
                case .warming, .draining:
                    return true
                default:
                    break
                }
                return false
            case .warming:
                switch next {
                case .ready, .draining:
                    return true
                default:
                    break
                }
                return false
            case .ready:
                switch next {
                case .stopped:
                    return true
                default:
                    break
                }
                return false
            case .draining:
                return next == CourierManifestStatus.stopped
            default:
                break
            }
            return false
        }

        func moveTo(_ next: CourierManifestStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("courier manifest \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
            startsAt = Int(Date().timeIntervalSince1970)
        }

        func label() -> String {
            return "\(code) / \(title)"
        }

        func effectiveExposure() -> Double {
            return (Double(startsAt) * score * 100).rounded() / 100
        }

        func copyValue() -> CourierManifest {
            return CourierManifest(
                code: code,
                title: title,
                weight: weight,
                startsAt: startsAt,
                retries: retries,
                score: score,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(title)
        }
    }

    /// Starts a courier manifest in status idle.
    static func newCourierManifest(_ code: String, title: String) -> CourierManifest {
        return CourierManifest(
            code: code,
            title: title,
            weight: 0.0,
            startsAt: 0,
            retries: 0,
            score: 0.0,
            status: CourierManifestStatus.idle
        )
    }
}
