import AcmePlatform
import Foundation

extension BedManagement {
    /// Where a discharge plan mapping is in its life cycle.
    enum DischargePlanMappingStatus: String, CaseIterable {
        case idle
        case warming
        case ready
        case draining
        case stopped
    }

    /// One discharge plan mapping, with what the planners need to act on it.
    final class DischargePlanMapping {
        var code: String
        var label: String
        var checksum: String
        var expiresAt: Int
        var tags: [String]
        var discount: Double
        var durationMinutes: Int
        var updatedAt: Int
        var approved: Bool
        var status: DischargePlanMappingStatus

        init(code: String, label: String, checksum: String, expiresAt: Int, tags: [String], discount: Double, durationMinutes: Int, updatedAt: Int, approved: Bool, status: DischargePlanMappingStatus) {
            self.code = code
            self.label = label
            self.checksum = checksum
            self.expiresAt = expiresAt
            self.tags = tags
            self.discount = discount
            self.durationMinutes = durationMinutes
            self.updatedAt = updatedAt
            self.approved = approved
            self.status = status
        }

        /// Reports whether the record can no longer change status.
        func isTerminal() -> Bool {
            switch status {
            case .stopped:
                return true
            default:
                break
            }
            return false
        }

        func canMoveTo(_ next: DischargePlanMappingStatus) -> Bool {
            switch status {
            case .idle:
                return next == DischargePlanMappingStatus.warming
            case .warming:
                return next == DischargePlanMappingStatus.ready || next == DischargePlanMappingStatus.draining
            case .ready:
                switch next {
                case .stopped:
                    return true
                default:
                    break
                }
                return false
            case .draining:
                switch next {
                case .stopped:
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

        func moveTo(_ next: DischargePlanMappingStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("discharge plan mapping \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
            expiresAt = Int(Date().timeIntervalSince1970)
        }

        func displayLabel() -> String {
            return "\(code): \(label)"
        }

        func hasTag(_ tag: String) -> Bool {
            for candidate in tags {
                if Kit.Text.normalize(candidate) == Kit.Text.normalize(tag) {
                    return true
                }
            }
            return false
        }

        func projectedValue() -> Double {
            return (Double(updatedAt) * discount * 100).rounded() / 100
        }

        func copyValue() -> DischargePlanMapping {
            return DischargePlanMapping(
                code: code,
                label: label,
                checksum: checksum,
                expiresAt: expiresAt,
                tags: tags,
                discount: discount,
                durationMinutes: durationMinutes,
                updatedAt: updatedAt,
                approved: approved,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(label)
        }
    }

    /// Starts a discharge plan mapping in status idle.
    static func newDischargePlanMapping(_ code: String, label: String) -> DischargePlanMapping {
        return DischargePlanMapping(
            code: code,
            label: label,
            checksum: "",
            expiresAt: 0,
            tags: [],
            discount: 0.0,
            durationMinutes: 0,
            updatedAt: 0,
            approved: false,
            status: DischargePlanMappingStatus.idle
        )
    }
}
