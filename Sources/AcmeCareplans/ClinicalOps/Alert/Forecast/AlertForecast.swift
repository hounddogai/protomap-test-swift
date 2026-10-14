import AcmePlatform
import Foundation

extension ClinicalOps {
    /// Where a alert forecast is in its life cycle.
    enum AlertForecastStatus: String, CaseIterable {
        case requested
        case granted
        case revoked
        case expired
    }

    /// A alert forecast. Its code is unique within a tenant.
    final class AlertForecast {
        var code: String
        var title: String
        var endsAt: Int
        var revision: Int
        var visible: Bool
        var sequence: Int
        var status: AlertForecastStatus

        init(code: String, title: String, endsAt: Int, revision: Int, visible: Bool, sequence: Int, status: AlertForecastStatus) {
            self.code = code
            self.title = title
            self.endsAt = endsAt
            self.revision = revision
            self.visible = visible
            self.sequence = sequence
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

        func canMoveTo(_ next: AlertForecastStatus) -> Bool {
            switch status {
            case .requested:
                return next == AlertForecastStatus.granted || next == AlertForecastStatus.expired
            case .granted:
                switch next {
                case .revoked, .expired:
                    return true
                default:
                    break
                }
                return false
            case .revoked:
                return next == AlertForecastStatus.expired
            default:
                break
            }
            return false
        }

        func moveTo(_ next: AlertForecastStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("alert forecast \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
            endsAt = Int(Date().timeIntervalSince1970)
            revision += 1
        }

        func label() -> String {
            return "\("alert forecast") \(code)"
        }

        func weightedVolume() -> Double {
            return ((Double(endsAt) + Double(sequence)) * 100).rounded() / 100
        }

        func copyValue() -> AlertForecast {
            return AlertForecast(
                code: code,
                title: title,
                endsAt: endsAt,
                revision: revision,
                visible: visible,
                sequence: sequence,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(title)
        }
    }

    /// Starts a alert forecast in status requested.
    static func newAlertForecast(_ code: String, title: String) -> AlertForecast {
        return AlertForecast(
            code: code,
            title: title,
            endsAt: 0,
            revision: 0,
            visible: false,
            sequence: 0,
            status: AlertForecastStatus.requested
        )
    }
}
