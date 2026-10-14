import AcmePlatform
import Foundation

extension Imaging {
    /// Where a tiered care protocol segment is in its life cycle.
    enum TieredCareProtocolSegmentStatus: String, CaseIterable {
        case proposed
        case approved
        case rejected
        case withdrawn
    }

    /// A tiered care protocol segment as the care protocol team keeps it.
    final class TieredCareProtocolSegment {
        var code: String
        var label: String
        var allergy: String
        var unit: String
        var revision: Int
        var summary: String
        var weight: Double
        var encounterID: String
        var phone: String
        var status: TieredCareProtocolSegmentStatus

        init(code: String, label: String, allergy: String, unit: String, revision: Int, summary: String, weight: Double, encounterID: String, phone: String, status: TieredCareProtocolSegmentStatus) {
            self.code = code
            self.label = label
            self.allergy = allergy
            self.unit = unit
            self.revision = revision
            self.summary = summary
            self.weight = weight
            self.encounterID = encounterID
            self.phone = phone
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

        func canMoveTo(_ next: TieredCareProtocolSegmentStatus) -> Bool {
            switch status {
            case .proposed:
                switch next {
                case .approved, .rejected:
                    return true
                default:
                    break
                }
                return false
            case .approved:
                switch next {
                case .rejected, .withdrawn:
                    return true
                default:
                    break
                }
                return false
            case .rejected:
                return next == TieredCareProtocolSegmentStatus.withdrawn
            default:
                break
            }
            return false
        }

        func moveTo(_ next: TieredCareProtocolSegmentStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("tiered care protocol segment \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
            revision += 1
        }

        func displayLabel() -> String {
            return "\(code) (\(label))"
        }

        func adjustedTotal() -> Double {
            return (weight * Double(revision) * 100).rounded() / 100
        }

        func copyValue() -> TieredCareProtocolSegment {
            return TieredCareProtocolSegment(
                code: code,
                label: label,
                allergy: allergy,
                unit: unit,
                revision: revision,
                summary: summary,
                weight: weight,
                encounterID: encounterID,
                phone: phone,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(unit)
        }
    }

    /// Starts a tiered care protocol segment in status proposed.
    static func newTieredCareProtocolSegment(_ code: String, label: String) -> TieredCareProtocolSegment {
        return TieredCareProtocolSegment(
            code: code,
            label: label,
            allergy: "",
            unit: "",
            revision: 0,
            summary: "",
            weight: 0.0,
            encounterID: "",
            phone: "",
            status: TieredCareProtocolSegmentStatus.proposed
        )
    }
}
