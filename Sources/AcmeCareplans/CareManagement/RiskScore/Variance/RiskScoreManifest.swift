import AcmePlatform
import Foundation

extension CareManagement {
    /// Where a risk score manifest is in its life cycle.
    enum RiskScoreManifestStatus: String, CaseIterable {
        case idle
        case warming
        case ready
        case draining
        case stopped
    }

    /// The record of a risk score manifest and its current status.
    final class RiskScoreManifest {
        var code: String
        var label: String
        var graceDays: Int
        var channel: String
        var revision: Int
        var startsAt: Int
        var visible: Bool
        var expiresAt: Int
        var locale: String
        var status: RiskScoreManifestStatus

        init(code: String, label: String, graceDays: Int, channel: String, revision: Int, startsAt: Int, visible: Bool, expiresAt: Int, locale: String, status: RiskScoreManifestStatus) {
            self.code = code
            self.label = label
            self.graceDays = graceDays
            self.channel = channel
            self.revision = revision
            self.startsAt = startsAt
            self.visible = visible
            self.expiresAt = expiresAt
            self.locale = locale
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

        func canMoveTo(_ next: RiskScoreManifestStatus) -> Bool {
            switch status {
            case .idle:
                switch next {
                case .draining, .stopped:
                    return true
                default:
                    break
                }
                return false
            case .warming:
                return next == RiskScoreManifestStatus.draining
            case .ready:
                switch next {
                case .stopped:
                    return true
                default:
                    break
                }
                return false
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

        func moveTo(_ next: RiskScoreManifestStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("risk score manifest \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
            startsAt = Int(Date().timeIntervalSince1970)
            revision += 1
        }

        func displayLabel() -> String {
            return "\(code) [\(label)]"
        }

        func projectedTotal() -> Double {
            return (Double(startsAt) * Double(graceDays) * 100).rounded() / 100
        }

        func copyValue() -> RiskScoreManifest {
            return RiskScoreManifest(
                code: code,
                label: label,
                graceDays: graceDays,
                channel: channel,
                revision: revision,
                startsAt: startsAt,
                visible: visible,
                expiresAt: expiresAt,
                locale: locale,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(channel)
        }
    }

    /// Starts a risk score manifest in status idle.
    static func newRiskScoreManifest(_ code: String, label: String) -> RiskScoreManifest {
        return RiskScoreManifest(
            code: code,
            label: label,
            graceDays: 0,
            channel: "",
            revision: 0,
            startsAt: 0,
            visible: false,
            expiresAt: 0,
            locale: "",
            status: RiskScoreManifestStatus.idle
        )
    }
}
