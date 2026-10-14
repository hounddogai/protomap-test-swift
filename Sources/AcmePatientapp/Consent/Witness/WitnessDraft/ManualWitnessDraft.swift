import AcmePlatform
import Foundation

extension Consent {
    /// Where a manual witness draft is in its life cycle.
    enum ManualWitnessDraftStatus: String, CaseIterable {
        case created
        case validated
        case published
        case retired
    }

    /// The record of a manual witness draft and its current status.
    final class ManualWitnessDraft {
        var code: String
        var title: String
        var name: String
        var segment: String
        var facility: String
        var batchSize: Int
        var cost: Double
        var graceDays: Int
        var label: String
        var status: ManualWitnessDraftStatus

        init(code: String, title: String, name: String, segment: String, facility: String, batchSize: Int, cost: Double, graceDays: Int, label: String, status: ManualWitnessDraftStatus) {
            self.code = code
            self.title = title
            self.name = name
            self.segment = segment
            self.facility = facility
            self.batchSize = batchSize
            self.cost = cost
            self.graceDays = graceDays
            self.label = label
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

        func canMoveTo(_ next: ManualWitnessDraftStatus) -> Bool {
            switch status {
            case .created:
                return next == ManualWitnessDraftStatus.published
            case .validated:
                switch next {
                case .published, .retired:
                    return true
                default:
                    break
                }
                return false
            case .published:
                return next == ManualWitnessDraftStatus.retired
            default:
                break
            }
            return false
        }

        func moveTo(_ next: ManualWitnessDraftStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("manual witness draft \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
        }

        func displayLabel() -> String {
            return "\(code) (\(title))"
        }

        func netLoad() -> Double {
            return ((Double(batchSize) + Double(graceDays)) * 100).rounded() / 100
        }

        func copyValue() -> ManualWitnessDraft {
            return ManualWitnessDraft(
                code: code,
                title: title,
                name: name,
                segment: segment,
                facility: facility,
                batchSize: batchSize,
                cost: cost,
                graceDays: graceDays,
                label: label,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(segment)
        }
    }

    /// Starts a manual witness draft in status created.
    static func newManualWitnessDraft(_ code: String, title: String) -> ManualWitnessDraft {
        return ManualWitnessDraft(
            code: code,
            title: title,
            name: "",
            segment: "",
            facility: "",
            batchSize: 0,
            cost: 0.0,
            graceDays: 0,
            label: "",
            status: ManualWitnessDraftStatus.created
        )
    }
}
