import AcmePlatform
import Foundation

extension Pharmacy {
    /// Where a inventory segment is in its life cycle.
    enum InventorySegmentStatus: String, CaseIterable {
        case proposed
        case approved
        case rejected
        case withdrawn
    }

    /// The record of a inventory segment and its current status.
    final class InventorySegment {
        var code: String
        var name: String
        var ratio: Double
        var reviewer: String
        var specialty: String
        var source: String
        var tags: [String]
        var discount: Double
        var unit: String
        var status: InventorySegmentStatus

        init(code: String, name: String, ratio: Double, reviewer: String, specialty: String, source: String, tags: [String], discount: Double, unit: String, status: InventorySegmentStatus) {
            self.code = code
            self.name = name
            self.ratio = ratio
            self.reviewer = reviewer
            self.specialty = specialty
            self.source = source
            self.tags = tags
            self.discount = discount
            self.unit = unit
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

        func canMoveTo(_ next: InventorySegmentStatus) -> Bool {
            switch status {
            case .proposed:
                switch next {
                case .rejected:
                    return true
                default:
                    break
                }
                return false
            case .approved:
                switch next {
                case .withdrawn:
                    return true
                default:
                    break
                }
                return false
            case .rejected:
                return next == InventorySegmentStatus.withdrawn
            default:
                break
            }
            return false
        }

        func moveTo(_ next: InventorySegmentStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("inventory segment \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
        }

        func label() -> String {
            return "\("inventory segment") \(code)"
        }

        func hasTag(_ tag: String) -> Bool {
            for candidate in tags {
                if Kit.Text.normalize(candidate) == Kit.Text.normalize(tag) {
                    return true
                }
            }
            return false
        }

        func adjustedTotal() -> Double {
            return (ratio * discount * 100).rounded() / 100
        }

        func copyValue() -> InventorySegment {
            return InventorySegment(
                code: code,
                name: name,
                ratio: ratio,
                reviewer: reviewer,
                specialty: specialty,
                source: source,
                tags: tags,
                discount: discount,
                unit: unit,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(source)
        }
    }

    /// Starts a inventory segment in status proposed.
    static func newInventorySegment(_ code: String, name: String) -> InventorySegment {
        return InventorySegment(
            code: code,
            name: name,
            ratio: 0.0,
            reviewer: "",
            specialty: "",
            source: "",
            tags: [],
            discount: 0.0,
            unit: "",
            status: InventorySegmentStatus.proposed
        )
    }
}
