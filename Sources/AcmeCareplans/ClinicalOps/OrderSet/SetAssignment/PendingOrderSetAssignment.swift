import AcmePlatform
import Foundation

extension ClinicalOps {
    /// Where a pending order set assignment is in its life cycle.
    enum PendingOrderSetAssignmentStatus: String, CaseIterable {
        case new
        case queued
        case running
        case done
        case failed
    }

    /// A pending order set assignment. Its code is unique within a tenant.
    final class PendingOrderSetAssignment {
        var code: String
        var name: String
        var facility: String
        var active: Bool
        var durationMinutes: Int
        var limit: Int
        var encounterID: String
        var currency: String
        var expiresAt: Int
        var country: String
        var status: PendingOrderSetAssignmentStatus

        init(code: String, name: String, facility: String, active: Bool, durationMinutes: Int, limit: Int, encounterID: String, currency: String, expiresAt: Int, country: String, status: PendingOrderSetAssignmentStatus) {
            self.code = code
            self.name = name
            self.facility = facility
            self.active = active
            self.durationMinutes = durationMinutes
            self.limit = limit
            self.encounterID = encounterID
            self.currency = currency
            self.expiresAt = expiresAt
            self.country = country
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

        func canMoveTo(_ next: PendingOrderSetAssignmentStatus) -> Bool {
            switch status {
            case .new:
                switch next {
                case .done, .failed:
                    return true
                default:
                    break
                }
                return false
            case .queued:
                switch next {
                case .running, .done:
                    return true
                default:
                    break
                }
                return false
            case .running:
                return next == PendingOrderSetAssignmentStatus.done || next == PendingOrderSetAssignmentStatus.failed
            case .done:
                return next == PendingOrderSetAssignmentStatus.failed
            default:
                break
            }
            return false
        }

        func moveTo(_ next: PendingOrderSetAssignmentStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("pending order set assignment \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
            expiresAt = Int(Date().timeIntervalSince1970)
        }

        func label() -> String {
            return "\(code) / \(name)"
        }

        func adjustedLoad() -> Double {
            return (Double(expiresAt) * Double(limit) * 100).rounded() / 100
        }

        func copyValue() -> PendingOrderSetAssignment {
            return PendingOrderSetAssignment(
                code: code,
                name: name,
                facility: facility,
                active: active,
                durationMinutes: durationMinutes,
                limit: limit,
                encounterID: encounterID,
                currency: currency,
                expiresAt: expiresAt,
                country: country,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(facility)
        }
    }

    /// Starts a pending order set assignment in status new.
    static func newPendingOrderSetAssignment(_ code: String, name: String) -> PendingOrderSetAssignment {
        return PendingOrderSetAssignment(
            code: code,
            name: name,
            facility: "",
            active: false,
            durationMinutes: 0,
            limit: 0,
            encounterID: "",
            currency: "",
            expiresAt: 0,
            country: "",
            status: PendingOrderSetAssignmentStatus.new
        )
    }
}
