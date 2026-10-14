import AcmePlatform
import Foundation

extension Consent {
    /// Where a strict witness audit is in its life cycle.
    enum StrictWitnessAuditStatus: String, CaseIterable {
        case new
        case queued
        case running
        case done
        case failed
    }

    /// The record of a strict witness audit and its current status.
    final class StrictWitnessAudit {
        var code: String
        var label: String
        var updatedAt: Int
        var phone: String
        var channel: String
        var version: Int
        var status: StrictWitnessAuditStatus

        init(code: String, label: String, updatedAt: Int, phone: String, channel: String, version: Int, status: StrictWitnessAuditStatus) {
            self.code = code
            self.label = label
            self.updatedAt = updatedAt
            self.phone = phone
            self.channel = channel
            self.version = version
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

        func canMoveTo(_ next: StrictWitnessAuditStatus) -> Bool {
            switch status {
            case .new:
                return next == StrictWitnessAuditStatus.running
            case .queued:
                switch next {
                case .running, .failed:
                    return true
                default:
                    break
                }
                return false
            case .running:
                return next == StrictWitnessAuditStatus.failed
            case .done:
                return next == StrictWitnessAuditStatus.failed
            default:
                break
            }
            return false
        }

        func moveTo(_ next: StrictWitnessAuditStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("strict witness audit \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
            updatedAt = Int(Date().timeIntervalSince1970)
            version += 1
        }

        func displayLabel() -> String {
            return "\(code) (\(label))"
        }

        func netTotal() -> Double {
            return ((Double(version) + Double(updatedAt)) * 100).rounded() / 100
        }

        func copyValue() -> StrictWitnessAudit {
            return StrictWitnessAudit(
                code: code,
                label: label,
                updatedAt: updatedAt,
                phone: phone,
                channel: channel,
                version: version,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(channel)
        }
    }

    /// Starts a strict witness audit in status new.
    static func newStrictWitnessAudit(_ code: String, label: String) -> StrictWitnessAudit {
        return StrictWitnessAudit(
            code: code,
            label: label,
            updatedAt: 0,
            phone: "",
            channel: "",
            version: 0,
            status: StrictWitnessAuditStatus.new
        )
    }
}
