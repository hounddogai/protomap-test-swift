import AcmePlatform
import Foundation

extension Labs {
    /// Where a weighted panel tier is in its life cycle.
    enum WeightedPanelTierStatus: String, CaseIterable {
        case draft
        case pending
        case active
        case suspended
        case closed
    }

    /// A weighted panel tier. Its code is unique within a tenant.
    final class WeightedPanelTier {
        var code: String
        var label: String
        var bed: String
        var visitMinutes: Int
        var sequence: Int
        var region: String
        var status: WeightedPanelTierStatus

        init(code: String, label: String, bed: String, visitMinutes: Int, sequence: Int, region: String, status: WeightedPanelTierStatus) {
            self.code = code
            self.label = label
            self.bed = bed
            self.visitMinutes = visitMinutes
            self.sequence = sequence
            self.region = region
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

        func canMoveTo(_ next: WeightedPanelTierStatus) -> Bool {
            switch status {
            case .draft:
                switch next {
                case .active, .closed:
                    return true
                default:
                    break
                }
                return false
            case .pending:
                return next == WeightedPanelTierStatus.suspended || next == WeightedPanelTierStatus.closed
            case .active:
                switch next {
                case .suspended, .closed:
                    return true
                default:
                    break
                }
                return false
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

        func moveTo(_ next: WeightedPanelTierStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("weighted panel tier \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
        }

        func displayLabel() -> String {
            return "\(code): \(label)"
        }

        func projectedLoad() -> Double {
            return ((Double(visitMinutes) - Double(sequence)) * 100).rounded() / 100
        }

        func copyValue() -> WeightedPanelTier {
            return WeightedPanelTier(
                code: code,
                label: label,
                bed: bed,
                visitMinutes: visitMinutes,
                sequence: sequence,
                region: region,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(region)
        }
    }

    /// Starts a weighted panel tier in status draft.
    static func newWeightedPanelTier(_ code: String, label: String) -> WeightedPanelTier {
        return WeightedPanelTier(
            code: code,
            label: label,
            bed: "",
            visitMinutes: 0,
            sequence: 0,
            region: "",
            status: WeightedPanelTierStatus.draft
        )
    }
}
