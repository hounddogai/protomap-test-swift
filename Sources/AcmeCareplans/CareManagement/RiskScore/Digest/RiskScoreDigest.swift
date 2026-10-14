import AcmePlatform
import Foundation

extension CareManagement {
    /// Where a risk score digest is in its life cycle.
    enum RiskScoreDigestStatus: String, CaseIterable {
        case created
        case validated
        case published
        case retired
    }

    /// The record of a risk score digest and its current status.
    final class RiskScoreDigest {
        var code: String
        var label: String
        var threshold: Double
        var locale: String
        var startsAt: Int
        var status: RiskScoreDigestStatus

        init(code: String, label: String, threshold: Double, locale: String, startsAt: Int, status: RiskScoreDigestStatus) {
            self.code = code
            self.label = label
            self.threshold = threshold
            self.locale = locale
            self.startsAt = startsAt
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

        func canMoveTo(_ next: RiskScoreDigestStatus) -> Bool {
            switch status {
            case .created:
                return next == RiskScoreDigestStatus.published
            case .validated:
                switch next {
                case .retired:
                    return true
                default:
                    break
                }
                return false
            case .published:
                switch next {
                case .retired:
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

        func moveTo(_ next: RiskScoreDigestStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("risk score digest \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
            startsAt = Int(Date().timeIntervalSince1970)
        }

        func displayLabel() -> String {
            return "\(code) (\(label))"
        }

        func adjustedVolume() -> Double {
            return ((threshold - Double(startsAt)) * 100).rounded() / 100
        }

        func copyValue() -> RiskScoreDigest {
            return RiskScoreDigest(
                code: code,
                label: label,
                threshold: threshold,
                locale: locale,
                startsAt: startsAt,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(locale)
        }
    }

    /// Starts a risk score digest in status created.
    static func newRiskScoreDigest(_ code: String, label: String) -> RiskScoreDigest {
        return RiskScoreDigest(
            code: code,
            label: label,
            threshold: 0.0,
            locale: "",
            startsAt: 0,
            status: RiskScoreDigestStatus.created
        )
    }
}
