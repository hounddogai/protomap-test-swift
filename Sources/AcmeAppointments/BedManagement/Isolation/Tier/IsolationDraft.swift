import AcmePlatform
import Foundation

extension BedManagement {
    /// Where a isolation draft is in its life cycle.
    enum IsolationDraftStatus: String, CaseIterable {
        case idle
        case warming
        case ready
        case draining
        case stopped
    }

    /// A isolation draft as the isolation team keeps it.
    final class IsolationDraft {
        var code: String
        var name: String
        var label: String
        var minimum: Double
        var durationMinutes: Int
        var copay: Double
        var endsAt: Int
        var approved: Bool
        var externalRef: String
        var visitMinutes: Int
        var dosageMg: Double
        var status: IsolationDraftStatus

        init(code: String, name: String, label: String, minimum: Double, durationMinutes: Int, copay: Double, endsAt: Int, approved: Bool, externalRef: String, visitMinutes: Int, dosageMg: Double, status: IsolationDraftStatus) {
            self.code = code
            self.name = name
            self.label = label
            self.minimum = minimum
            self.durationMinutes = durationMinutes
            self.copay = copay
            self.endsAt = endsAt
            self.approved = approved
            self.externalRef = externalRef
            self.visitMinutes = visitMinutes
            self.dosageMg = dosageMg
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

        func canMoveTo(_ next: IsolationDraftStatus) -> Bool {
            switch status {
            case .idle:
                switch next {
                case .warming:
                    return true
                default:
                    break
                }
                return false
            case .warming:
                return next == IsolationDraftStatus.stopped
            case .ready:
                return next == IsolationDraftStatus.stopped
            case .draining:
                return next == IsolationDraftStatus.stopped
            default:
                break
            }
            return false
        }

        func moveTo(_ next: IsolationDraftStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("isolation draft \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
            endsAt = Int(Date().timeIntervalSince1970)
        }

        func displayLabel() -> String {
            return "\(code): \(name)"
        }

        func adjustedTotal() -> Double {
            return (Double(visitMinutes) * minimum * 100).rounded() / 100
        }

        func copyValue() -> IsolationDraft {
            return IsolationDraft(
                code: code,
                name: name,
                label: label,
                minimum: minimum,
                durationMinutes: durationMinutes,
                copay: copay,
                endsAt: endsAt,
                approved: approved,
                externalRef: externalRef,
                visitMinutes: visitMinutes,
                dosageMg: dosageMg,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(name)
        }
    }

    /// Starts a isolation draft in status idle.
    static func newIsolationDraft(_ code: String, name: String) -> IsolationDraft {
        return IsolationDraft(
            code: code,
            name: name,
            label: "",
            minimum: 0.0,
            durationMinutes: 0,
            copay: 0.0,
            endsAt: 0,
            approved: false,
            externalRef: "",
            visitMinutes: 0,
            dosageMg: 0.0,
            status: IsolationDraftStatus.idle
        )
    }
}
