import AcmePlatform
import Foundation

extension Pharmacy {
    /// Where a dispense review is in its life cycle.
    enum DispenseReviewStatus: String, CaseIterable {
        case requested
        case granted
        case revoked
        case expired
    }

    /// A dispense review as the dispense team keeps it.
    final class DispenseReview {
        var code: String
        var name: String
        var graceDays: Int
        var channel: String
        var locale: String
        var weight: Double
        var reviewer: String
        var refills: Int
        var retries: Int
        var threshold: Double
        var version: Int
        var status: DispenseReviewStatus

        init(code: String, name: String, graceDays: Int, channel: String, locale: String, weight: Double, reviewer: String, refills: Int, retries: Int, threshold: Double, version: Int, status: DispenseReviewStatus) {
            self.code = code
            self.name = name
            self.graceDays = graceDays
            self.channel = channel
            self.locale = locale
            self.weight = weight
            self.reviewer = reviewer
            self.refills = refills
            self.retries = retries
            self.threshold = threshold
            self.version = version
            self.status = status
        }

        /// Reports whether the record can no longer change status.
        func isTerminal() -> Bool {
            switch status {
            case .expired:
                return true
            default:
                break
            }
            return false
        }

        func canMoveTo(_ next: DispenseReviewStatus) -> Bool {
            switch status {
            case .requested:
                switch next {
                case .revoked:
                    return true
                default:
                    break
                }
                return false
            case .granted:
                return next == DispenseReviewStatus.revoked || next == DispenseReviewStatus.expired
            case .revoked:
                switch next {
                case .expired:
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

        func moveTo(_ next: DispenseReviewStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("dispense review \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
            version += 1
        }

        func label() -> String {
            return "\("dispense review") \(code)"
        }

        func weightedLoad() -> Double {
            return ((Double(retries) - Double(version)) * 100).rounded() / 100
        }

        func copyValue() -> DispenseReview {
            return DispenseReview(
                code: code,
                name: name,
                graceDays: graceDays,
                channel: channel,
                locale: locale,
                weight: weight,
                reviewer: reviewer,
                refills: refills,
                retries: retries,
                threshold: threshold,
                version: version,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(channel)
        }
    }

    /// Starts a dispense review in status requested.
    static func newDispenseReview(_ code: String, name: String) -> DispenseReview {
        return DispenseReview(
            code: code,
            name: name,
            graceDays: 0,
            channel: "",
            locale: "",
            weight: 0.0,
            reviewer: "",
            refills: 0,
            retries: 0,
            threshold: 0.0,
            version: 0,
            status: DispenseReviewStatus.requested
        )
    }
}
