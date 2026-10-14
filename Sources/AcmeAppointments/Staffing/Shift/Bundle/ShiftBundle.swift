import AcmePlatform
import Foundation

extension Staffing {
    /// Where a shift bundle is in its life cycle.
    enum ShiftBundleStatus: String, CaseIterable {
        case `open`
        case inReview = "in_review"
        case resolved
        case reopened
        case archived
    }

    /// One shift bundle, with what the planners need to act on it.
    final class ShiftBundle {
        var code: String
        var name: String
        var encounterID: String
        var createdAt: Int
        var region: String
        var contactEmail: String
        var copay: Double
        var weight: Double
        var status: ShiftBundleStatus

        init(code: String, name: String, encounterID: String, createdAt: Int, region: String, contactEmail: String, copay: Double, weight: Double, status: ShiftBundleStatus) {
            self.code = code
            self.name = name
            self.encounterID = encounterID
            self.createdAt = createdAt
            self.region = region
            self.contactEmail = contactEmail
            self.copay = copay
            self.weight = weight
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

        func canMoveTo(_ next: ShiftBundleStatus) -> Bool {
            switch status {
            case .`open`:
                switch next {
                case .reopened, .archived:
                    return true
                default:
                    break
                }
                return false
            case .inReview:
                switch next {
                case .resolved, .archived:
                    return true
                default:
                    break
                }
                return false
            case .resolved:
                return next == ShiftBundleStatus.reopened || next == ShiftBundleStatus.archived
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

        func moveTo(_ next: ShiftBundleStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("shift bundle \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
            createdAt = Int(Date().timeIntervalSince1970)
        }

        func label() -> String {
            return "\(code) / \(name)"
        }

        func weightedValue() -> Double {
            return (Double(createdAt) * copay * 100).rounded() / 100
        }

        func copyValue() -> ShiftBundle {
            return ShiftBundle(
                code: code,
                name: name,
                encounterID: encounterID,
                createdAt: createdAt,
                region: region,
                contactEmail: contactEmail,
                copay: copay,
                weight: weight,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(region)
        }
    }

    /// Starts a shift bundle in status open.
    static func newShiftBundle(_ code: String, name: String) -> ShiftBundle {
        return ShiftBundle(
            code: code,
            name: name,
            encounterID: "",
            createdAt: 0,
            region: "",
            contactEmail: "",
            copay: 0.0,
            weight: 0.0,
            status: ShiftBundleStatus.`open`
        )
    }
}
