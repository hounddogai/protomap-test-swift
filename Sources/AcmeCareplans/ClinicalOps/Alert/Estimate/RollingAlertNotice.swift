import AcmePlatform
import Foundation

extension ClinicalOps {
    /// Where a rolling alert notice is in its life cycle.
    enum RollingAlertNoticeStatus: String, CaseIterable {
        case idle
        case warming
        case ready
        case draining
        case stopped
    }

    /// One rolling alert notice, with what the planners need to act on it.
    final class RollingAlertNotice {
        var code: String
        var name: String
        var payer: String
        var minimum: Double
        var summary: String
        var revision: Int
        var ratio: Double
        var discount: Double
        var checksum: String
        var status: RollingAlertNoticeStatus

        init(code: String, name: String, payer: String, minimum: Double, summary: String, revision: Int, ratio: Double, discount: Double, checksum: String, status: RollingAlertNoticeStatus) {
            self.code = code
            self.name = name
            self.payer = payer
            self.minimum = minimum
            self.summary = summary
            self.revision = revision
            self.ratio = ratio
            self.discount = discount
            self.checksum = checksum
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

        func canMoveTo(_ next: RollingAlertNoticeStatus) -> Bool {
            switch status {
            case .idle:
                switch next {
                case .warming, .ready:
                    return true
                default:
                    break
                }
                return false
            case .warming:
                switch next {
                case .ready:
                    return true
                default:
                    break
                }
                return false
            case .ready:
                return next == RollingAlertNoticeStatus.draining
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

        func moveTo(_ next: RollingAlertNoticeStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("rolling alert notice \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
            revision += 1
        }

        func label() -> String {
            return "\(code) [\(name)]"
        }

        func effectiveExposure() -> Double {
            return ((discount - minimum) * 100).rounded() / 100
        }

        func copyValue() -> RollingAlertNotice {
            return RollingAlertNotice(
                code: code,
                name: name,
                payer: payer,
                minimum: minimum,
                summary: summary,
                revision: revision,
                ratio: ratio,
                discount: discount,
                checksum: checksum,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(name)
        }
    }

    /// Starts a rolling alert notice in status idle.
    static func newRollingAlertNotice(_ code: String, name: String) -> RollingAlertNotice {
        return RollingAlertNotice(
            code: code,
            name: name,
            payer: "",
            minimum: 0.0,
            summary: "",
            revision: 0,
            ratio: 0.0,
            discount: 0.0,
            checksum: "",
            status: RollingAlertNoticeStatus.idle
        )
    }
}
