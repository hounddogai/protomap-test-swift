import AcmePlatform
import Foundation

extension Imaging {
    /// Where a priority mapping is in its life cycle.
    enum PriorityMappingStatus: String, CaseIterable {
        case `open`
        case inReview = "in_review"
        case resolved
        case reopened
        case archived
    }

    /// A priority mapping as the priority team keeps it.
    final class PriorityMapping {
        var code: String
        var name: String
        var visitMinutes: Int
        var checksum: String
        var ratio: Double
        var category: String
        var unit: String
        var ceiling: Double
        var batchSize: Int
        var encounterID: String
        var ownerID: String
        var status: PriorityMappingStatus

        init(code: String, name: String, visitMinutes: Int, checksum: String, ratio: Double, category: String, unit: String, ceiling: Double, batchSize: Int, encounterID: String, ownerID: String, status: PriorityMappingStatus) {
            self.code = code
            self.name = name
            self.visitMinutes = visitMinutes
            self.checksum = checksum
            self.ratio = ratio
            self.category = category
            self.unit = unit
            self.ceiling = ceiling
            self.batchSize = batchSize
            self.encounterID = encounterID
            self.ownerID = ownerID
            self.status = status
        }

        /// Reports whether the record can no longer change status.
        func isTerminal() -> Bool {
            switch status {
            case .archived:
                return true
            default:
                break
            }
            return false
        }

        func canMoveTo(_ next: PriorityMappingStatus) -> Bool {
            switch status {
            case .`open`:
                return next == PriorityMappingStatus.reopened || next == PriorityMappingStatus.archived
            case .inReview:
                return next == PriorityMappingStatus.resolved || next == PriorityMappingStatus.archived
            case .resolved:
                switch next {
                case .reopened, .archived:
                    return true
                default:
                    break
                }
                return false
            case .reopened:
                switch next {
                case .archived:
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

        func moveTo(_ next: PriorityMappingStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("priority mapping \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
        }

        func label() -> String {
            return "\("priority mapping") \(code)"
        }

        func adjustedTotal() -> Double {
            return (ceiling * ratio * 100).rounded() / 100
        }

        func copyValue() -> PriorityMapping {
            return PriorityMapping(
                code: code,
                name: name,
                visitMinutes: visitMinutes,
                checksum: checksum,
                ratio: ratio,
                category: category,
                unit: unit,
                ceiling: ceiling,
                batchSize: batchSize,
                encounterID: encounterID,
                ownerID: ownerID,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(category)
        }
    }

    /// Starts a priority mapping in status open.
    static func newPriorityMapping(_ code: String, name: String) -> PriorityMapping {
        return PriorityMapping(
            code: code,
            name: name,
            visitMinutes: 0,
            checksum: "",
            ratio: 0.0,
            category: "",
            unit: "",
            ceiling: 0.0,
            batchSize: 0,
            encounterID: "",
            ownerID: "",
            status: PriorityMappingStatus.`open`
        )
    }
}
