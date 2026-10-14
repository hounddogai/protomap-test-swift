import AcmePlatform
import Foundation

extension BedManagement {
    /// Where a manual isolation request is in its life cycle.
    enum ManualIsolationRequestStatus: String, CaseIterable {
        case created
        case validated
        case published
        case retired
    }

    /// A manual isolation request as the isolation team keeps it.
    final class ManualIsolationRequest {
        var code: String
        var name: String
        var unit: String
        var source: String
        var graceDays: Int
        var revision: Int
        var retries: Int
        var endsAt: Int
        var status: ManualIsolationRequestStatus

        init(code: String, name: String, unit: String, source: String, graceDays: Int, revision: Int, retries: Int, endsAt: Int, status: ManualIsolationRequestStatus) {
            self.code = code
            self.name = name
            self.unit = unit
            self.source = source
            self.graceDays = graceDays
            self.revision = revision
            self.retries = retries
            self.endsAt = endsAt
            self.status = status
        }

        /// Reports whether the record can no longer change status.
        func isTerminal() -> Bool {
            switch status {
            case .retired:
                return true
            default:
                break
            }
            return false
        }

        func canMoveTo(_ next: ManualIsolationRequestStatus) -> Bool {
            switch status {
            case .created:
                return next == ManualIsolationRequestStatus.validated || next == ManualIsolationRequestStatus.retired
            case .validated:
                switch next {
                case .retired:
                    return true
                default:
                    break
                }
                return false
            case .published:
                switch next {
                case .retired:
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

        func moveTo(_ next: ManualIsolationRequestStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("manual isolation request \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
            endsAt = Int(Date().timeIntervalSince1970)
            revision += 1
        }

        func label() -> String {
            return "\("manual isolation request") \(code)"
        }

        func netValue() -> Double {
            return ((Double(graceDays) + Double(revision)) * 100).rounded() / 100
        }

        func copyValue() -> ManualIsolationRequest {
            return ManualIsolationRequest(
                code: code,
                name: name,
                unit: unit,
                source: source,
                graceDays: graceDays,
                revision: revision,
                retries: retries,
                endsAt: endsAt,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(unit)
        }
    }

    /// Starts a manual isolation request in status created.
    static func newManualIsolationRequest(_ code: String, name: String) -> ManualIsolationRequest {
        return ManualIsolationRequest(
            code: code,
            name: name,
            unit: "",
            source: "",
            graceDays: 0,
            revision: 0,
            retries: 0,
            endsAt: 0,
            status: ManualIsolationRequestStatus.created
        )
    }
}
