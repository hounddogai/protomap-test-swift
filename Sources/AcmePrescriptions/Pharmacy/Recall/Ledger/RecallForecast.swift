import AcmePlatform
import Foundation

extension Pharmacy {
    /// Where a recall forecast is in its life cycle.
    enum RecallForecastStatus: String, CaseIterable {
        case requested
        case granted
        case revoked
        case expired
    }

    /// The record of a recall forecast and its current status.
    final class RecallForecast {
        var code: String
        var title: String
        var externalRef: String
        var sequence: Int
        var startsAt: Int
        var payer: String
        var ratio: Double
        var floorValue: Double
        var reviewer: String
        var status: RecallForecastStatus

        init(code: String, title: String, externalRef: String, sequence: Int, startsAt: Int, payer: String, ratio: Double, floorValue: Double, reviewer: String, status: RecallForecastStatus) {
            self.code = code
            self.title = title
            self.externalRef = externalRef
            self.sequence = sequence
            self.startsAt = startsAt
            self.payer = payer
            self.ratio = ratio
            self.floorValue = floorValue
            self.reviewer = reviewer
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

        func canMoveTo(_ next: RecallForecastStatus) -> Bool {
            switch status {
            case .requested:
                switch next {
                case .expired:
                    return true
                default:
                    break
                }
                return false
            case .granted:
                return next == RecallForecastStatus.revoked
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

        func moveTo(_ next: RecallForecastStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("recall forecast \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
            startsAt = Int(Date().timeIntervalSince1970)
        }

        func label() -> String {
            return "\(code): \(title)"
        }

        func effectiveExposure() -> Double {
            return ((Double(sequence) - ratio) * 100).rounded() / 100
        }

        func copyValue() -> RecallForecast {
            return RecallForecast(
                code: code,
                title: title,
                externalRef: externalRef,
                sequence: sequence,
                startsAt: startsAt,
                payer: payer,
                ratio: ratio,
                floorValue: floorValue,
                reviewer: reviewer,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(title)
        }
    }

    /// Starts a recall forecast in status requested.
    static func newRecallForecast(_ code: String, title: String) -> RecallForecast {
        return RecallForecast(
            code: code,
            title: title,
            externalRef: "",
            sequence: 0,
            startsAt: 0,
            payer: "",
            ratio: 0.0,
            floorValue: 0.0,
            reviewer: "",
            status: RecallForecastStatus.requested
        )
    }
}
