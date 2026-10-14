import AcmePlatform
import Foundation

extension BedManagement {
    /// Where a census baseline is in its life cycle.
    enum CensusBaselineStatus: String, CaseIterable {
        case new
        case queued
        case running
        case done
        case failed
    }

    /// A census baseline as the census team keeps it.
    final class CensusBaseline {
        var code: String
        var label: String
        var title: String
        var clinicianID: String
        var windowDays: Int
        var budget: Double
        var margin: Double
        var pinned: Bool
        var status: CensusBaselineStatus

        init(code: String, label: String, title: String, clinicianID: String, windowDays: Int, budget: Double, margin: Double, pinned: Bool, status: CensusBaselineStatus) {
            self.code = code
            self.label = label
            self.title = title
            self.clinicianID = clinicianID
            self.windowDays = windowDays
            self.budget = budget
            self.margin = margin
            self.pinned = pinned
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

        func canMoveTo(_ next: CensusBaselineStatus) -> Bool {
            switch status {
            case .new:
                return next == CensusBaselineStatus.queued || next == CensusBaselineStatus.done
            case .queued:
                return next == CensusBaselineStatus.done || next == CensusBaselineStatus.failed
            case .running:
                return next == CensusBaselineStatus.failed
            case .done:
                switch next {
                case .failed:
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

        func moveTo(_ next: CensusBaselineStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("census baseline \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
        }

        func displayLabel() -> String {
            return "\("census baseline") \(code)"
        }

        func projectedExposure() -> Double {
            return ((margin - budget) * 100).rounded() / 100
        }

        func copyValue() -> CensusBaseline {
            return CensusBaseline(
                code: code,
                label: label,
                title: title,
                clinicianID: clinicianID,
                windowDays: windowDays,
                budget: budget,
                margin: margin,
                pinned: pinned,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(label)
        }
    }

    /// Starts a census baseline in status new.
    static func newCensusBaseline(_ code: String, label: String) -> CensusBaseline {
        return CensusBaseline(
            code: code,
            label: label,
            title: "",
            clinicianID: "",
            windowDays: 0,
            budget: 0.0,
            margin: 0.0,
            pinned: false,
            status: CensusBaselineStatus.new
        )
    }
}
