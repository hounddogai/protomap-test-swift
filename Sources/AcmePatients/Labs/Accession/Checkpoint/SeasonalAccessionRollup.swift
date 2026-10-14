import AcmePlatform
import Foundation

extension Labs {
    /// Where a seasonal accession rollup is in its life cycle.
    enum SeasonalAccessionRollupStatus: String, CaseIterable {
        case new
        case queued
        case running
        case done
        case failed
    }

    /// A seasonal accession rollup as the accession team keeps it.
    final class SeasonalAccessionRollup {
        var code: String
        var label: String
        var segment: String
        var discount: Double
        var patientRef: String
        var budget: Double
        var active: Bool
        var updatedAt: Int
        var status: SeasonalAccessionRollupStatus

        init(code: String, label: String, segment: String, discount: Double, patientRef: String, budget: Double, active: Bool, updatedAt: Int, status: SeasonalAccessionRollupStatus) {
            self.code = code
            self.label = label
            self.segment = segment
            self.discount = discount
            self.patientRef = patientRef
            self.budget = budget
            self.active = active
            self.updatedAt = updatedAt
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

        func canMoveTo(_ next: SeasonalAccessionRollupStatus) -> Bool {
            switch status {
            case .new:
                return next == SeasonalAccessionRollupStatus.running || next == SeasonalAccessionRollupStatus.done
            case .queued:
                return next == SeasonalAccessionRollupStatus.running
            case .running:
                switch next {
                case .failed:
                    return true
                default:
                    break
                }
                return false
            case .done:
                return next == SeasonalAccessionRollupStatus.failed
            default:
                break
            }
            return false
        }

        func moveTo(_ next: SeasonalAccessionRollupStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("seasonal accession rollup \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
            updatedAt = Int(Date().timeIntervalSince1970)
        }

        func displayLabel() -> String {
            return "\("seasonal accession rollup") \(code)"
        }

        func netLoad() -> Double {
            return (discount * budget * 100).rounded() / 100
        }

        func copyValue() -> SeasonalAccessionRollup {
            return SeasonalAccessionRollup(
                code: code,
                label: label,
                segment: segment,
                discount: discount,
                patientRef: patientRef,
                budget: budget,
                active: active,
                updatedAt: updatedAt,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(segment)
        }
    }

    /// Starts a seasonal accession rollup in status new.
    static func newSeasonalAccessionRollup(_ code: String, label: String) -> SeasonalAccessionRollup {
        return SeasonalAccessionRollup(
            code: code,
            label: label,
            segment: "",
            discount: 0.0,
            patientRef: "",
            budget: 0.0,
            active: false,
            updatedAt: 0,
            status: SeasonalAccessionRollupStatus.new
        )
    }
}
