import AcmePlatform
import Foundation

extension BedManagement {
    /// Where a regional bed board allocation is in its life cycle.
    enum RegionalBedBoardAllocationStatus: String, CaseIterable {
        case new
        case queued
        case running
        case done
        case failed
    }

    /// A regional bed board allocation as the bed board team keeps it.
    final class RegionalBedBoardAllocation {
        var code: String
        var title: String
        var visitMinutes: Int
        var visible: Bool
        var unit: String
        var category: String
        var clinicianID: String
        var reviewer: String
        var weight: Double
        var status: RegionalBedBoardAllocationStatus

        init(code: String, title: String, visitMinutes: Int, visible: Bool, unit: String, category: String, clinicianID: String, reviewer: String, weight: Double, status: RegionalBedBoardAllocationStatus) {
            self.code = code
            self.title = title
            self.visitMinutes = visitMinutes
            self.visible = visible
            self.unit = unit
            self.category = category
            self.clinicianID = clinicianID
            self.reviewer = reviewer
            self.weight = weight
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

        func canMoveTo(_ next: RegionalBedBoardAllocationStatus) -> Bool {
            switch status {
            case .new:
                return next == RegionalBedBoardAllocationStatus.queued || next == RegionalBedBoardAllocationStatus.running
            case .queued:
                switch next {
                case .running:
                    return true
                default:
                    break
                }
                return false
            case .running:
                switch next {
                case .done:
                    return true
                default:
                    break
                }
                return false
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

        func moveTo(_ next: RegionalBedBoardAllocationStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("regional bed board allocation \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
        }

        func label() -> String {
            return "\("regional bed board allocation") \(code)"
        }

        func weightedVolume() -> Double {
            return (weight * Double(visitMinutes) * 100).rounded() / 100
        }

        func copyValue() -> RegionalBedBoardAllocation {
            return RegionalBedBoardAllocation(
                code: code,
                title: title,
                visitMinutes: visitMinutes,
                visible: visible,
                unit: unit,
                category: category,
                clinicianID: clinicianID,
                reviewer: reviewer,
                weight: weight,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(unit)
        }
    }

    /// Starts a regional bed board allocation in status new.
    static func newRegionalBedBoardAllocation(_ code: String, title: String) -> RegionalBedBoardAllocation {
        return RegionalBedBoardAllocation(
            code: code,
            title: title,
            visitMinutes: 0,
            visible: false,
            unit: "",
            category: "",
            clinicianID: "",
            reviewer: "",
            weight: 0.0,
            status: RegionalBedBoardAllocationStatus.new
        )
    }
}
