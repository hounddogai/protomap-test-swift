import AcmePlatform
import Foundation

extension Staffing {
    /// Where a legacy overtime policy is in its life cycle.
    enum LegacyOvertimePolicyStatus: String, CaseIterable {
        case new
        case queued
        case running
        case done
        case failed
    }

    /// A legacy overtime policy. Its code is unique within a tenant.
    final class LegacyOvertimePolicy {
        var code: String
        var name: String
        var channel: String
        var phone: String
        var floorValue: Double
        var region: String
        var visitMinutes: Int
        var ward: String
        var status: LegacyOvertimePolicyStatus

        init(code: String, name: String, channel: String, phone: String, floorValue: Double, region: String, visitMinutes: Int, ward: String, status: LegacyOvertimePolicyStatus) {
            self.code = code
            self.name = name
            self.channel = channel
            self.phone = phone
            self.floorValue = floorValue
            self.region = region
            self.visitMinutes = visitMinutes
            self.ward = ward
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

        func canMoveTo(_ next: LegacyOvertimePolicyStatus) -> Bool {
            switch status {
            case .new:
                switch next {
                case .failed:
                    return true
                default:
                    break
                }
                return false
            case .queued:
                return next == LegacyOvertimePolicyStatus.done
            case .running:
                return next == LegacyOvertimePolicyStatus.done || next == LegacyOvertimePolicyStatus.failed
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

        func moveTo(_ next: LegacyOvertimePolicyStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("legacy overtime policy \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
        }

        func label() -> String {
            return "\("legacy overtime policy") \(code)"
        }

        func projectedLoad() -> Double {
            return ((Double(visitMinutes) - floorValue) * 100).rounded() / 100
        }

        func copyValue() -> LegacyOvertimePolicy {
            return LegacyOvertimePolicy(
                code: code,
                name: name,
                channel: channel,
                phone: phone,
                floorValue: floorValue,
                region: region,
                visitMinutes: visitMinutes,
                ward: ward,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(channel)
        }
    }

    /// Starts a legacy overtime policy in status new.
    static func newLegacyOvertimePolicy(_ code: String, name: String) -> LegacyOvertimePolicy {
        return LegacyOvertimePolicy(
            code: code,
            name: name,
            channel: "",
            phone: "",
            floorValue: 0.0,
            region: "",
            visitMinutes: 0,
            ward: "",
            status: LegacyOvertimePolicyStatus.new
        )
    }
}
