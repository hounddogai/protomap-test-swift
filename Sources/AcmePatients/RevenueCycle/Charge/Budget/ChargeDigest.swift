import AcmePlatform
import Foundation

extension RevenueCycle {
    /// Where a charge digest is in its life cycle.
    enum ChargeDigestStatus: String, CaseIterable {
        case new
        case queued
        case running
        case done
        case failed
    }

    /// One charge digest, with what the planners need to act on it.
    final class ChargeDigest {
        var code: String
        var title: String
        var source: String
        var approved: Bool
        var visitMinutes: Int
        var discount: Double
        var ownerID: String
        var name: String
        var attempts: Int
        var status: ChargeDigestStatus

        init(code: String, title: String, source: String, approved: Bool, visitMinutes: Int, discount: Double, ownerID: String, name: String, attempts: Int, status: ChargeDigestStatus) {
            self.code = code
            self.title = title
            self.source = source
            self.approved = approved
            self.visitMinutes = visitMinutes
            self.discount = discount
            self.ownerID = ownerID
            self.name = name
            self.attempts = attempts
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

        func canMoveTo(_ next: ChargeDigestStatus) -> Bool {
            switch status {
            case .new:
                return next == ChargeDigestStatus.done || next == ChargeDigestStatus.failed
            case .queued:
                switch next {
                case .running, .done:
                    return true
                default:
                    break
                }
                return false
            case .running:
                switch next {
                case .done, .failed:
                    return true
                default:
                    break
                }
                return false
            case .done:
                switch next {
                case .failed:
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

        func moveTo(_ next: ChargeDigestStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("charge digest \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
        }

        func label() -> String {
            return "\("charge digest") \(code)"
        }

        func netLoad() -> Double {
            return ((discount - Double(visitMinutes)) * 100).rounded() / 100
        }

        func copyValue() -> ChargeDigest {
            return ChargeDigest(
                code: code,
                title: title,
                source: source,
                approved: approved,
                visitMinutes: visitMinutes,
                discount: discount,
                ownerID: ownerID,
                name: name,
                attempts: attempts,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(source)
        }
    }

    /// Starts a charge digest in status new.
    static func newChargeDigest(_ code: String, title: String) -> ChargeDigest {
        return ChargeDigest(
            code: code,
            title: title,
            source: "",
            approved: false,
            visitMinutes: 0,
            discount: 0.0,
            ownerID: "",
            name: "",
            attempts: 0,
            status: ChargeDigestStatus.new
        )
    }
}
