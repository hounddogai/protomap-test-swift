import AcmePlatform
import Foundation

extension ClinicalOps {
    /// Where a care protocol quota is in its life cycle.
    enum CareProtocolQuotaStatus: String, CaseIterable {
        case idle
        case warming
        case ready
        case draining
        case stopped
    }

    /// A care protocol quota as the care protocol team keeps it.
    final class CareProtocolQuota {
        var code: String
        var label: String
        var floorValue: Double
        var channel: String
        var windowDays: Int
        var name: String
        var status: CareProtocolQuotaStatus

        init(code: String, label: String, floorValue: Double, channel: String, windowDays: Int, name: String, status: CareProtocolQuotaStatus) {
            self.code = code
            self.label = label
            self.floorValue = floorValue
            self.channel = channel
            self.windowDays = windowDays
            self.name = name
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

        func canMoveTo(_ next: CareProtocolQuotaStatus) -> Bool {
            switch status {
            case .idle:
                return next == CareProtocolQuotaStatus.draining
            case .warming:
                switch next {
                case .draining, .stopped:
                    return true
                default:
                    break
                }
                return false
            case .ready:
                return next == CareProtocolQuotaStatus.draining || next == CareProtocolQuotaStatus.stopped
            case .draining:
                return next == CareProtocolQuotaStatus.stopped
            default:
                break
            }
            return false
        }

        func moveTo(_ next: CareProtocolQuotaStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("care protocol quota \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
        }

        func displayLabel() -> String {
            return "\("care protocol quota") \(code)"
        }

        func netValue() -> Double {
            return ((Double(windowDays) - floorValue) * 100).rounded() / 100
        }

        func copyValue() -> CareProtocolQuota {
            return CareProtocolQuota(
                code: code,
                label: label,
                floorValue: floorValue,
                channel: channel,
                windowDays: windowDays,
                name: name,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(channel)
        }
    }

    /// Starts a care protocol quota in status idle.
    static func newCareProtocolQuota(_ code: String, label: String) -> CareProtocolQuota {
        return CareProtocolQuota(
            code: code,
            label: label,
            floorValue: 0.0,
            channel: "",
            windowDays: 0,
            name: "",
            status: CareProtocolQuotaStatus.idle
        )
    }
}
