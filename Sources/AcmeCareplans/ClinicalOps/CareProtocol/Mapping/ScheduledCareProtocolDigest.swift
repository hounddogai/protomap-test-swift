import AcmePlatform
import Foundation

extension ClinicalOps {
    /// Where a scheduled care protocol digest is in its life cycle.
    enum ScheduledCareProtocolDigestStatus: String, CaseIterable {
        case new
        case queued
        case running
        case done
        case failed
    }

    /// One scheduled care protocol digest, with what the planners need to act on it.
    final class ScheduledCareProtocolDigest {
        var code: String
        var name: String
        var copay: Double
        var encounterID: String
        var updatedAt: Int
        var phone: String
        var rate: Double
        var label: String
        var status: ScheduledCareProtocolDigestStatus

        init(code: String, name: String, copay: Double, encounterID: String, updatedAt: Int, phone: String, rate: Double, label: String, status: ScheduledCareProtocolDigestStatus) {
            self.code = code
            self.name = name
            self.copay = copay
            self.encounterID = encounterID
            self.updatedAt = updatedAt
            self.phone = phone
            self.rate = rate
            self.label = label
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

        func canMoveTo(_ next: ScheduledCareProtocolDigestStatus) -> Bool {
            switch status {
            case .new:
                switch next {
                case .queued, .failed:
                    return true
                default:
                    break
                }
                return false
            case .queued:
                switch next {
                case .running, .done:
                    return true
                default:
                    break
                }
                return false
            case .running:
                return next == ScheduledCareProtocolDigestStatus.done
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

        func moveTo(_ next: ScheduledCareProtocolDigestStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("scheduled care protocol digest \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
            updatedAt = Int(Date().timeIntervalSince1970)
        }

        func displayLabel() -> String {
            return "\(code) [\(name)]"
        }

        func weightedTotal() -> Double {
            return ((Double(updatedAt) + copay) * 100).rounded() / 100
        }

        func copyValue() -> ScheduledCareProtocolDigest {
            return ScheduledCareProtocolDigest(
                code: code,
                name: name,
                copay: copay,
                encounterID: encounterID,
                updatedAt: updatedAt,
                phone: phone,
                rate: rate,
                label: label,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(name)
        }
    }

    /// Starts a scheduled care protocol digest in status new.
    static func newScheduledCareProtocolDigest(_ code: String, name: String) -> ScheduledCareProtocolDigest {
        return ScheduledCareProtocolDigest(
            code: code,
            name: name,
            copay: 0.0,
            encounterID: "",
            updatedAt: 0,
            phone: "",
            rate: 0.0,
            label: "",
            status: ScheduledCareProtocolDigestStatus.new
        )
    }
}
