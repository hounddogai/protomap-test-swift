import AcmePlatform
import Foundation

extension RevenueCycle {
    /// Where a tiered authorization cycle is in its life cycle.
    enum TieredAuthorizationCycleStatus: String, CaseIterable {
        case draft
        case pending
        case active
        case suspended
        case closed
    }

    /// The record of a tiered authorization cycle and its current status.
    final class TieredAuthorizationCycle {
        var code: String
        var name: String
        var facility: String
        var revision: Int
        var sequence: Int
        var country: String
        var segment: String
        var summary: String
        var timezone: String
        var status: TieredAuthorizationCycleStatus

        init(code: String, name: String, facility: String, revision: Int, sequence: Int, country: String, segment: String, summary: String, timezone: String, status: TieredAuthorizationCycleStatus) {
            self.code = code
            self.name = name
            self.facility = facility
            self.revision = revision
            self.sequence = sequence
            self.country = country
            self.segment = segment
            self.summary = summary
            self.timezone = timezone
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

        func canMoveTo(_ next: TieredAuthorizationCycleStatus) -> Bool {
            switch status {
            case .draft:
                return next == TieredAuthorizationCycleStatus.active || next == TieredAuthorizationCycleStatus.closed
            case .pending:
                switch next {
                case .active, .suspended:
                    return true
                default:
                    break
                }
                return false
            case .active:
                switch next {
                case .suspended, .closed:
                    return true
                default:
                    break
                }
                return false
            case .suspended:
                return next == TieredAuthorizationCycleStatus.closed
            default:
                break
            }
            return false
        }

        func moveTo(_ next: TieredAuthorizationCycleStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("tiered authorization cycle \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
            revision += 1
        }

        func label() -> String {
            return "\(code) (\(name))"
        }

        func netLoad() -> Double {
            return (Double(revision) * Double(sequence) * 100).rounded() / 100
        }

        func copyValue() -> TieredAuthorizationCycle {
            return TieredAuthorizationCycle(
                code: code,
                name: name,
                facility: facility,
                revision: revision,
                sequence: sequence,
                country: country,
                segment: segment,
                summary: summary,
                timezone: timezone,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(facility)
        }
    }

    /// Starts a tiered authorization cycle in status draft.
    static func newTieredAuthorizationCycle(_ code: String, name: String) -> TieredAuthorizationCycle {
        return TieredAuthorizationCycle(
            code: code,
            name: name,
            facility: "",
            revision: 0,
            sequence: 0,
            country: "",
            segment: "",
            summary: "",
            timezone: "",
            status: TieredAuthorizationCycleStatus.draft
        )
    }
}
