import AcmePlatform
import Foundation

extension Consent {
    /// Where a revocation threshold is in its life cycle.
    enum RevocationThresholdStatus: String, CaseIterable {
        case created
        case validated
        case published
        case retired
    }

    /// The record of a revocation threshold and its current status.
    final class RevocationThreshold {
        var code: String
        var name: String
        var budget: Double
        var notes: String
        var active: Bool
        var summary: String
        var visitMinutes: Int
        var facility: String
        var status: RevocationThresholdStatus

        init(code: String, name: String, budget: Double, notes: String, active: Bool, summary: String, visitMinutes: Int, facility: String, status: RevocationThresholdStatus) {
            self.code = code
            self.name = name
            self.budget = budget
            self.notes = notes
            self.active = active
            self.summary = summary
            self.visitMinutes = visitMinutes
            self.facility = facility
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

        func canMoveTo(_ next: RevocationThresholdStatus) -> Bool {
            switch status {
            case .created:
                switch next {
                case .validated:
                    return true
                default:
                    break
                }
                return false
            case .validated:
                switch next {
                case .published, .retired:
                    return true
                default:
                    break
                }
                return false
            case .published:
                return next == RevocationThresholdStatus.retired
            default:
                break
            }
            return false
        }

        func moveTo(_ next: RevocationThresholdStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("revocation threshold \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
        }

        func label() -> String {
            return "\("revocation threshold") \(code)"
        }

        func weightedTotal() -> Double {
            return ((budget - Double(visitMinutes)) * 100).rounded() / 100
        }

        func copyValue() -> RevocationThreshold {
            return RevocationThreshold(
                code: code,
                name: name,
                budget: budget,
                notes: notes,
                active: active,
                summary: summary,
                visitMinutes: visitMinutes,
                facility: facility,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(facility)
        }
    }

    /// Starts a revocation threshold in status created.
    static func newRevocationThreshold(_ code: String, name: String) -> RevocationThreshold {
        return RevocationThreshold(
            code: code,
            name: name,
            budget: 0.0,
            notes: "",
            active: false,
            summary: "",
            visitMinutes: 0,
            facility: "",
            status: RevocationThresholdStatus.created
        )
    }
}
