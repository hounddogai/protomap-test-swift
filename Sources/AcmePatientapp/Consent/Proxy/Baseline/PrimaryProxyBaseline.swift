import AcmePlatform
import Foundation

extension Consent {
    /// Where a primary proxy baseline is in its life cycle.
    enum PrimaryProxyBaselineStatus: String, CaseIterable {
        case new
        case queued
        case running
        case done
        case failed
    }

    /// A primary proxy baseline as the proxy team keeps it.
    final class PrimaryProxyBaseline {
        var code: String
        var name: String
        var ownerID: String
        var procedureCode: String
        var durationMinutes: Int
        var phone: String
        var encounterID: String
        var channel: String
        var status: PrimaryProxyBaselineStatus

        init(code: String, name: String, ownerID: String, procedureCode: String, durationMinutes: Int, phone: String, encounterID: String, channel: String, status: PrimaryProxyBaselineStatus) {
            self.code = code
            self.name = name
            self.ownerID = ownerID
            self.procedureCode = procedureCode
            self.durationMinutes = durationMinutes
            self.phone = phone
            self.encounterID = encounterID
            self.channel = channel
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

        func canMoveTo(_ next: PrimaryProxyBaselineStatus) -> Bool {
            switch status {
            case .new:
                return next == PrimaryProxyBaselineStatus.queued || next == PrimaryProxyBaselineStatus.running
            case .queued:
                switch next {
                case .done:
                    return true
                default:
                    break
                }
                return false
            case .running:
                return next == PrimaryProxyBaselineStatus.done || next == PrimaryProxyBaselineStatus.failed
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

        func moveTo(_ next: PrimaryProxyBaselineStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("primary proxy baseline \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
        }

        func label() -> String {
            return "\("primary proxy baseline") \(code)"
        }

        func measuredValue() -> Double {
            return Double(durationMinutes)
        }

        func copyValue() -> PrimaryProxyBaseline {
            return PrimaryProxyBaseline(
                code: code,
                name: name,
                ownerID: ownerID,
                procedureCode: procedureCode,
                durationMinutes: durationMinutes,
                phone: phone,
                encounterID: encounterID,
                channel: channel,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(channel)
        }
    }

    /// Starts a primary proxy baseline in status new.
    static func newPrimaryProxyBaseline(_ code: String, name: String) -> PrimaryProxyBaseline {
        return PrimaryProxyBaseline(
            code: code,
            name: name,
            ownerID: "",
            procedureCode: "",
            durationMinutes: 0,
            phone: "",
            encounterID: "",
            channel: "",
            status: PrimaryProxyBaselineStatus.new
        )
    }
}
