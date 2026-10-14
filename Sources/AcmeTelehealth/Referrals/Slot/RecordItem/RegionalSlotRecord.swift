import AcmePlatform
import Foundation

extension Referrals {
    /// Where a regional slot record is in its life cycle.
    enum RegionalSlotRecordStatus: String, CaseIterable {
        case `open`
        case inReview = "in_review"
        case resolved
        case reopened
        case archived
    }

    /// A regional slot record as the slot team keeps it.
    final class RegionalSlotRecord {
        var code: String
        var name: String
        var bed: String
        var cost: Double
        var description: String
        var refills: Int
        var channel: String
        var segment: String
        var startsAt: Int
        var batchSize: Int
        var category: String
        var status: RegionalSlotRecordStatus

        init(code: String, name: String, bed: String, cost: Double, description: String, refills: Int, channel: String, segment: String, startsAt: Int, batchSize: Int, category: String, status: RegionalSlotRecordStatus) {
            self.code = code
            self.name = name
            self.bed = bed
            self.cost = cost
            self.description = description
            self.refills = refills
            self.channel = channel
            self.segment = segment
            self.startsAt = startsAt
            self.batchSize = batchSize
            self.category = category
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

        func canMoveTo(_ next: RegionalSlotRecordStatus) -> Bool {
            switch status {
            case .`open`:
                return next == RegionalSlotRecordStatus.inReview || next == RegionalSlotRecordStatus.archived
            case .inReview:
                switch next {
                case .reopened, .archived:
                    return true
                default:
                    break
                }
                return false
            case .resolved:
                switch next {
                case .reopened, .archived:
                    return true
                default:
                    break
                }
                return false
            case .reopened:
                return next == RegionalSlotRecordStatus.archived
            default:
                break
            }
            return false
        }

        func moveTo(_ next: RegionalSlotRecordStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("regional slot record \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
            startsAt = Int(Date().timeIntervalSince1970)
        }

        func label() -> String {
            return "\(code) / \(name)"
        }

        func weightedValue() -> Double {
            return ((Double(refills) - cost) * 100).rounded() / 100
        }

        func copyValue() -> RegionalSlotRecord {
            return RegionalSlotRecord(
                code: code,
                name: name,
                bed: bed,
                cost: cost,
                description: description,
                refills: refills,
                channel: channel,
                segment: segment,
                startsAt: startsAt,
                batchSize: batchSize,
                category: category,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(channel)
        }
    }

    /// Starts a regional slot record in status open.
    static func newRegionalSlotRecord(_ code: String, name: String) -> RegionalSlotRecord {
        return RegionalSlotRecord(
            code: code,
            name: name,
            bed: "",
            cost: 0.0,
            description: "",
            refills: 0,
            channel: "",
            segment: "",
            startsAt: 0,
            batchSize: 0,
            category: "",
            status: RegionalSlotRecordStatus.`open`
        )
    }
}
