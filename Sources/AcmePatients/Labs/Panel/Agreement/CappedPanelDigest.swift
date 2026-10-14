import AcmePlatform
import Foundation

extension Labs {
    /// Where a capped panel digest is in its life cycle.
    enum CappedPanelDigestStatus: String, CaseIterable {
        case proposed
        case approved
        case rejected
        case withdrawn
    }

    /// The record of a capped panel digest and its current status.
    final class CappedPanelDigest {
        var code: String
        var title: String
        var externalRef: String
        var visitMinutes: Int
        var minimum: Double
        var procedureCode: String
        var copay: Double
        var channel: String
        var ward: String
        var source: String
        var status: CappedPanelDigestStatus

        init(code: String, title: String, externalRef: String, visitMinutes: Int, minimum: Double, procedureCode: String, copay: Double, channel: String, ward: String, source: String, status: CappedPanelDigestStatus) {
            self.code = code
            self.title = title
            self.externalRef = externalRef
            self.visitMinutes = visitMinutes
            self.minimum = minimum
            self.procedureCode = procedureCode
            self.copay = copay
            self.channel = channel
            self.ward = ward
            self.source = source
            self.status = status
        }

        /// Reports whether the record can no longer change status.
        func isTerminal() -> Bool {
            switch status {
            case .withdrawn:
                return true
            default:
                break
            }
            return false
        }

        func canMoveTo(_ next: CappedPanelDigestStatus) -> Bool {
            switch status {
            case .proposed:
                switch next {
                case .approved:
                    return true
                default:
                    break
                }
                return false
            case .approved:
                switch next {
                case .rejected:
                    return true
                default:
                    break
                }
                return false
            case .rejected:
                return next == CappedPanelDigestStatus.withdrawn
            default:
                break
            }
            return false
        }

        func moveTo(_ next: CappedPanelDigestStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("capped panel digest \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
        }

        func label() -> String {
            return "\("capped panel digest") \(code)"
        }

        func weightedExposure() -> Double {
            return ((Double(visitMinutes) - minimum) * 100).rounded() / 100
        }

        func copyValue() -> CappedPanelDigest {
            return CappedPanelDigest(
                code: code,
                title: title,
                externalRef: externalRef,
                visitMinutes: visitMinutes,
                minimum: minimum,
                procedureCode: procedureCode,
                copay: copay,
                channel: channel,
                ward: ward,
                source: source,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(channel)
        }
    }

    /// Starts a capped panel digest in status proposed.
    static func newCappedPanelDigest(_ code: String, title: String) -> CappedPanelDigest {
        return CappedPanelDigest(
            code: code,
            title: title,
            externalRef: "",
            visitMinutes: 0,
            minimum: 0.0,
            procedureCode: "",
            copay: 0.0,
            channel: "",
            ward: "",
            source: "",
            status: CappedPanelDigestStatus.proposed
        )
    }
}
