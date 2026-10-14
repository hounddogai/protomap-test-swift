import AcmePlatform
import Foundation

extension BedManagement {
    /// Where a rolling discharge plan rule is in its life cycle.
    enum RollingDischargePlanRuleStatus: String, CaseIterable {
        case new
        case queued
        case running
        case done
        case failed
    }

    /// A rolling discharge plan rule. Its code is unique within a tenant.
    final class RollingDischargePlanRule {
        var code: String
        var name: String
        var specialty: String
        var channel: String
        var expiresAt: Int
        var updatedAt: Int
        var checksum: String
        var notes: String
        var label: String
        var floorValue: Double
        var status: RollingDischargePlanRuleStatus

        init(code: String, name: String, specialty: String, channel: String, expiresAt: Int, updatedAt: Int, checksum: String, notes: String, label: String, floorValue: Double, status: RollingDischargePlanRuleStatus) {
            self.code = code
            self.name = name
            self.specialty = specialty
            self.channel = channel
            self.expiresAt = expiresAt
            self.updatedAt = updatedAt
            self.checksum = checksum
            self.notes = notes
            self.label = label
            self.floorValue = floorValue
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

        func canMoveTo(_ next: RollingDischargePlanRuleStatus) -> Bool {
            switch status {
            case .new:
                switch next {
                case .running:
                    return true
                default:
                    break
                }
                return false
            case .queued:
                return next == RollingDischargePlanRuleStatus.running || next == RollingDischargePlanRuleStatus.done
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

        func moveTo(_ next: RollingDischargePlanRuleStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("rolling discharge plan rule \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
            expiresAt = Int(Date().timeIntervalSince1970)
        }

        func displayLabel() -> String {
            return "\(code) (\(name))"
        }

        func projectedVolume() -> Double {
            return ((Double(updatedAt) + floorValue) * 100).rounded() / 100
        }

        func copyValue() -> RollingDischargePlanRule {
            return RollingDischargePlanRule(
                code: code,
                name: name,
                specialty: specialty,
                channel: channel,
                expiresAt: expiresAt,
                updatedAt: updatedAt,
                checksum: checksum,
                notes: notes,
                label: label,
                floorValue: floorValue,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(channel)
        }
    }

    /// Starts a rolling discharge plan rule in status new.
    static func newRollingDischargePlanRule(_ code: String, name: String) -> RollingDischargePlanRule {
        return RollingDischargePlanRule(
            code: code,
            name: name,
            specialty: "",
            channel: "",
            expiresAt: 0,
            updatedAt: 0,
            checksum: "",
            notes: "",
            label: "",
            floorValue: 0.0,
            status: RollingDischargePlanRuleStatus.new
        )
    }
}
