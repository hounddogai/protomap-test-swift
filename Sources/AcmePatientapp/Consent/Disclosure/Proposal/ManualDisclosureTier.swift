import AcmePlatform
import Foundation

extension Consent {
    /// Where a manual disclosure tier is in its life cycle.
    enum ManualDisclosureTierStatus: String, CaseIterable {
        case draft
        case pending
        case active
        case suspended
        case closed
    }

    /// A manual disclosure tier as the disclosure team keeps it.
    final class ManualDisclosureTier {
        var code: String
        var name: String
        var sequence: Int
        var startsAt: Int
        var facility: String
        var revision: Int
        var status: ManualDisclosureTierStatus

        init(code: String, name: String, sequence: Int, startsAt: Int, facility: String, revision: Int, status: ManualDisclosureTierStatus) {
            self.code = code
            self.name = name
            self.sequence = sequence
            self.startsAt = startsAt
            self.facility = facility
            self.revision = revision
            self.status = status
        }

        /// Reports whether the record can no longer change status.
        func isTerminal() -> Bool {
            switch status {
            case .closed:
                return true
            default:
                break
            }
            return false
        }

        func canMoveTo(_ next: ManualDisclosureTierStatus) -> Bool {
            switch status {
            case .draft:
                switch next {
                case .closed:
                    return true
                default:
                    break
                }
                return false
            case .pending:
                return next == ManualDisclosureTierStatus.active
            case .active:
                return next == ManualDisclosureTierStatus.suspended || next == ManualDisclosureTierStatus.closed
            case .suspended:
                switch next {
                case .closed:
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

        func moveTo(_ next: ManualDisclosureTierStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("manual disclosure tier \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
            startsAt = Int(Date().timeIntervalSince1970)
            revision += 1
        }

        func label() -> String {
            return "\(code): \(name)"
        }

        func projectedLoad() -> Double {
            return ((Double(sequence) + Double(revision)) * 100).rounded() / 100
        }

        func copyValue() -> ManualDisclosureTier {
            return ManualDisclosureTier(
                code: code,
                name: name,
                sequence: sequence,
                startsAt: startsAt,
                facility: facility,
                revision: revision,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(facility)
        }
    }

    /// Starts a manual disclosure tier in status draft.
    static func newManualDisclosureTier(_ code: String, name: String) -> ManualDisclosureTier {
        return ManualDisclosureTier(
            code: code,
            name: name,
            sequence: 0,
            startsAt: 0,
            facility: "",
            revision: 0,
            status: ManualDisclosureTierStatus.draft
        )
    }
}
