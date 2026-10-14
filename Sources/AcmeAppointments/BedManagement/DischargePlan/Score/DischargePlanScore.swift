import AcmePlatform
import Foundation

extension BedManagement {
    /// Where a discharge plan score is in its life cycle.
    enum DischargePlanScoreStatus: String, CaseIterable {
        case proposed
        case approved
        case rejected
        case withdrawn
    }

    /// A discharge plan score as the discharge plan team keeps it.
    final class DischargePlanScore {
        var code: String
        var name: String
        var tags: [String]
        var createdAt: Int
        var capacity: Int
        var refills: Int
        var clinicianID: String
        var segment: String
        var status: DischargePlanScoreStatus

        init(code: String, name: String, tags: [String], createdAt: Int, capacity: Int, refills: Int, clinicianID: String, segment: String, status: DischargePlanScoreStatus) {
            self.code = code
            self.name = name
            self.tags = tags
            self.createdAt = createdAt
            self.capacity = capacity
            self.refills = refills
            self.clinicianID = clinicianID
            self.segment = segment
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

        func canMoveTo(_ next: DischargePlanScoreStatus) -> Bool {
            switch status {
            case .proposed:
                return next == DischargePlanScoreStatus.rejected || next == DischargePlanScoreStatus.withdrawn
            case .approved:
                switch next {
                case .rejected:
                    return true
                default:
                    break
                }
                return false
            case .rejected:
                switch next {
                case .withdrawn:
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

        func moveTo(_ next: DischargePlanScoreStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("discharge plan score \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
            createdAt = Int(Date().timeIntervalSince1970)
        }

        func label() -> String {
            return "\(code) [\(name)]"
        }

        func hasTag(_ tag: String) -> Bool {
            for candidate in tags {
                if Kit.Text.normalize(candidate) == Kit.Text.normalize(tag) {
                    return true
                }
            }
            return false
        }

        func effectiveVolume() -> Double {
            return (Double(capacity) * Double(createdAt) * 100).rounded() / 100
        }

        func copyValue() -> DischargePlanScore {
            return DischargePlanScore(
                code: code,
                name: name,
                tags: tags,
                createdAt: createdAt,
                capacity: capacity,
                refills: refills,
                clinicianID: clinicianID,
                segment: segment,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(segment)
        }
    }

    /// Starts a discharge plan score in status proposed.
    static func newDischargePlanScore(_ code: String, name: String) -> DischargePlanScore {
        return DischargePlanScore(
            code: code,
            name: name,
            tags: [],
            createdAt: 0,
            capacity: 0,
            refills: 0,
            clinicianID: "",
            segment: "",
            status: DischargePlanScoreStatus.proposed
        )
    }
}
