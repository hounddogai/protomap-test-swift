import AcmePlatform
import Foundation

extension Consent {
    /// Where a primary proxy score is in its life cycle.
    enum PrimaryProxyScoreStatus: String, CaseIterable {
        case new
        case queued
        case running
        case done
        case failed
    }

    /// One primary proxy score, with what the planners need to act on it.
    final class PrimaryProxyScore {
        var code: String
        var name: String
        var locale: String
        var sequence: Int
        var limit: Int
        var startsAt: Int
        var floorValue: Double
        var acuity: Int
        var label: String
        var status: PrimaryProxyScoreStatus

        init(code: String, name: String, locale: String, sequence: Int, limit: Int, startsAt: Int, floorValue: Double, acuity: Int, label: String, status: PrimaryProxyScoreStatus) {
            self.code = code
            self.name = name
            self.locale = locale
            self.sequence = sequence
            self.limit = limit
            self.startsAt = startsAt
            self.floorValue = floorValue
            self.acuity = acuity
            self.label = label
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

        func canMoveTo(_ next: PrimaryProxyScoreStatus) -> Bool {
            switch status {
            case .new:
                switch next {
                case .queued, .failed:
                    return true
                default:
                    break
                }
                return false
            case .queued:
                switch next {
                case .running, .failed:
                    return true
                default:
                    break
                }
                return false
            case .running:
                switch next {
                case .done:
                    return true
                default:
                    break
                }
                return false
            case .done:
                return next == PrimaryProxyScoreStatus.failed
            default:
                break
            }
            return false
        }

        func moveTo(_ next: PrimaryProxyScoreStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("primary proxy score \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
            startsAt = Int(Date().timeIntervalSince1970)
        }

        func displayLabel() -> String {
            return "\("primary proxy score") \(code)"
        }

        func weightedVolume() -> Double {
            return ((floorValue - Double(acuity)) * 100).rounded() / 100
        }

        func copyValue() -> PrimaryProxyScore {
            return PrimaryProxyScore(
                code: code,
                name: name,
                locale: locale,
                sequence: sequence,
                limit: limit,
                startsAt: startsAt,
                floorValue: floorValue,
                acuity: acuity,
                label: label,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(locale)
        }
    }

    /// Starts a primary proxy score in status new.
    static func newPrimaryProxyScore(_ code: String, name: String) -> PrimaryProxyScore {
        return PrimaryProxyScore(
            code: code,
            name: name,
            locale: "",
            sequence: 0,
            limit: 0,
            startsAt: 0,
            floorValue: 0.0,
            acuity: 0,
            label: "",
            status: PrimaryProxyScoreStatus.new
        )
    }
}
