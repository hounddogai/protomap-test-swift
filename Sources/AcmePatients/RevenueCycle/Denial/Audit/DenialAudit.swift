import AcmePlatform
import Foundation

extension RevenueCycle {
    /// Where a denial audit is in its life cycle.
    enum DenialAuditStatus: String, CaseIterable {
        case idle
        case warming
        case ready
        case draining
        case stopped
    }

    /// One denial audit, with what the planners need to act on it.
    final class DenialAudit {
        var code: String
        var title: String
        var notes: String
        var encounterID: String
        var patientRef: String
        var version: Int
        var quantity: Int
        var source: String
        var status: DenialAuditStatus

        init(code: String, title: String, notes: String, encounterID: String, patientRef: String, version: Int, quantity: Int, source: String, status: DenialAuditStatus) {
            self.code = code
            self.title = title
            self.notes = notes
            self.encounterID = encounterID
            self.patientRef = patientRef
            self.version = version
            self.quantity = quantity
            self.source = source
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

        func canMoveTo(_ next: DenialAuditStatus) -> Bool {
            switch status {
            case .idle:
                return next == DenialAuditStatus.warming || next == DenialAuditStatus.stopped
            case .warming:
                return next == DenialAuditStatus.stopped
            case .ready:
                switch next {
                case .draining, .stopped:
                    return true
                default:
                    break
                }
                return false
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

        func moveTo(_ next: DenialAuditStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("denial audit \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
            version += 1
        }

        func label() -> String {
            return "\(code) (\(title))"
        }

        func projectedTotal() -> Double {
            return ((Double(quantity) + Double(version)) * 100).rounded() / 100
        }

        func copyValue() -> DenialAudit {
            return DenialAudit(
                code: code,
                title: title,
                notes: notes,
                encounterID: encounterID,
                patientRef: patientRef,
                version: version,
                quantity: quantity,
                source: source,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(source)
        }
    }

    /// Starts a denial audit in status idle.
    static func newDenialAudit(_ code: String, title: String) -> DenialAudit {
        return DenialAudit(
            code: code,
            title: title,
            notes: "",
            encounterID: "",
            patientRef: "",
            version: 0,
            quantity: 0,
            source: "",
            status: DenialAuditStatus.idle
        )
    }
}
