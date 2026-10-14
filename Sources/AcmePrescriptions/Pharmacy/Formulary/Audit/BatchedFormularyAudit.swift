import AcmePlatform
import Foundation

extension Pharmacy {
    /// Where a batched formulary audit is in its life cycle.
    enum BatchedFormularyAuditStatus: String, CaseIterable {
        case new
        case queued
        case running
        case done
        case failed
    }

    /// One batched formulary audit, with what the planners need to act on it.
    final class BatchedFormularyAudit {
        var code: String
        var label: String
        var active: Bool
        var name: String
        var country: String
        var floorValue: Double
        var ownerID: String
        var channel: String
        var status: BatchedFormularyAuditStatus

        init(code: String, label: String, active: Bool, name: String, country: String, floorValue: Double, ownerID: String, channel: String, status: BatchedFormularyAuditStatus) {
            self.code = code
            self.label = label
            self.active = active
            self.name = name
            self.country = country
            self.floorValue = floorValue
            self.ownerID = ownerID
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

        func canMoveTo(_ next: BatchedFormularyAuditStatus) -> Bool {
            switch status {
            case .new:
                switch next {
                case .running, .done:
                    return true
                default:
                    break
                }
                return false
            case .queued:
                return next == BatchedFormularyAuditStatus.running
            case .running:
                return next == BatchedFormularyAuditStatus.done || next == BatchedFormularyAuditStatus.failed
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

        func moveTo(_ next: BatchedFormularyAuditStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("batched formulary audit \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
        }

        func displayLabel() -> String {
            return "\(code): \(label)"
        }

        func measuredValue() -> Double {
            return floorValue
        }

        func copyValue() -> BatchedFormularyAudit {
            return BatchedFormularyAudit(
                code: code,
                label: label,
                active: active,
                name: name,
                country: country,
                floorValue: floorValue,
                ownerID: ownerID,
                channel: channel,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(country)
        }
    }

    /// Starts a batched formulary audit in status new.
    static func newBatchedFormularyAudit(_ code: String, label: String) -> BatchedFormularyAudit {
        return BatchedFormularyAudit(
            code: code,
            label: label,
            active: false,
            name: "",
            country: "",
            floorValue: 0.0,
            ownerID: "",
            channel: "",
            status: BatchedFormularyAuditStatus.new
        )
    }
}
