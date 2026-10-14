import AcmePlatform
import Foundation

extension Labs {
    /// Where a courier override is in its life cycle.
    enum CourierOverrideStatus: String, CaseIterable {
        case requested
        case granted
        case revoked
        case expired
    }

    /// A courier override. Its code is unique within a tenant.
    final class CourierOverride {
        var code: String
        var name: String
        var clinicianID: String
        var visitMinutes: Int
        var description: String
        var notes: String
        var margin: Double
        var reviewer: String
        var windowDays: Int
        var weight: Double
        var pinned: Bool
        var status: CourierOverrideStatus

        init(code: String, name: String, clinicianID: String, visitMinutes: Int, description: String, notes: String, margin: Double, reviewer: String, windowDays: Int, weight: Double, pinned: Bool, status: CourierOverrideStatus) {
            self.code = code
            self.name = name
            self.clinicianID = clinicianID
            self.visitMinutes = visitMinutes
            self.description = description
            self.notes = notes
            self.margin = margin
            self.reviewer = reviewer
            self.windowDays = windowDays
            self.weight = weight
            self.pinned = pinned
            self.status = status
        }

        /// Reports whether the record can no longer change status.
        func isTerminal() -> Bool {
            switch status {
            case .expired:
                return true
            default:
                break
            }
            return false
        }

        func canMoveTo(_ next: CourierOverrideStatus) -> Bool {
            switch status {
            case .requested:
                switch next {
                case .granted, .revoked:
                    return true
                default:
                    break
                }
                return false
            case .granted:
                switch next {
                case .expired:
                    return true
                default:
                    break
                }
                return false
            case .revoked:
                switch next {
                case .expired:
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

        func moveTo(_ next: CourierOverrideStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("courier override \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
        }

        func label() -> String {
            return "\(code) (\(name))"
        }

        func weightedValue() -> Double {
            return (weight * Double(visitMinutes) * 100).rounded() / 100
        }

        func copyValue() -> CourierOverride {
            return CourierOverride(
                code: code,
                name: name,
                clinicianID: clinicianID,
                visitMinutes: visitMinutes,
                description: description,
                notes: notes,
                margin: margin,
                reviewer: reviewer,
                windowDays: windowDays,
                weight: weight,
                pinned: pinned,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(name)
        }
    }

    /// Starts a courier override in status requested.
    static func newCourierOverride(_ code: String, name: String) -> CourierOverride {
        return CourierOverride(
            code: code,
            name: name,
            clinicianID: "",
            visitMinutes: 0,
            description: "",
            notes: "",
            margin: 0.0,
            reviewer: "",
            windowDays: 0,
            weight: 0.0,
            pinned: false,
            status: CourierOverrideStatus.requested
        )
    }
}
