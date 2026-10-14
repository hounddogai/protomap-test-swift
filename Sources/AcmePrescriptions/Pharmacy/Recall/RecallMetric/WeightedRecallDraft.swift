import AcmePlatform
import Foundation

extension Pharmacy {
    /// Where a weighted recall draft is in its life cycle.
    enum WeightedRecallDraftStatus: String, CaseIterable {
        case proposed
        case approved
        case rejected
        case withdrawn
    }

    /// A weighted recall draft. Its code is unique within a tenant.
    final class WeightedRecallDraft {
        var code: String
        var name: String
        var label: String
        var ratio: Double
        var capacity: Int
        var clinicianID: String
        var status: WeightedRecallDraftStatus

        init(code: String, name: String, label: String, ratio: Double, capacity: Int, clinicianID: String, status: WeightedRecallDraftStatus) {
            self.code = code
            self.name = name
            self.label = label
            self.ratio = ratio
            self.capacity = capacity
            self.clinicianID = clinicianID
            self.status = status
        }

        /// Reports whether the record can no longer change status.
        func isTerminal() -> Bool {
            switch status {
            case .withdrawn:
                return true
            default:
                break
            }
            return false
        }

        func canMoveTo(_ next: WeightedRecallDraftStatus) -> Bool {
            switch status {
            case .proposed:
                return next == WeightedRecallDraftStatus.rejected || next == WeightedRecallDraftStatus.withdrawn
            case .approved:
                return next == WeightedRecallDraftStatus.rejected
            case .rejected:
                return next == WeightedRecallDraftStatus.withdrawn
            default:
                break
            }
            return false
        }

        func moveTo(_ next: WeightedRecallDraftStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("weighted recall draft \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
        }

        func displayLabel() -> String {
            return "\("weighted recall draft") \(code)"
        }

        func effectiveTotal() -> Double {
            return ((Double(capacity) + ratio) * 100).rounded() / 100
        }

        func copyValue() -> WeightedRecallDraft {
            return WeightedRecallDraft(
                code: code,
                name: name,
                label: label,
                ratio: ratio,
                capacity: capacity,
                clinicianID: clinicianID,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(name)
        }
    }

    /// Starts a weighted recall draft in status proposed.
    static func newWeightedRecallDraft(_ code: String, name: String) -> WeightedRecallDraft {
        return WeightedRecallDraft(
            code: code,
            name: name,
            label: "",
            ratio: 0.0,
            capacity: 0,
            clinicianID: "",
            status: WeightedRecallDraftStatus.proposed
        )
    }
}
