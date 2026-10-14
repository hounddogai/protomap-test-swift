import AcmePlatform
import Foundation

extension BedManagement {
    /// Where a bed board override is in its life cycle.
    enum BedBoardOverrideStatus: String, CaseIterable {
        case `open`
        case inReview = "in_review"
        case resolved
        case reopened
        case archived
    }

    /// One bed board override, with what the planners need to act on it.
    final class BedBoardOverride {
        var code: String
        var name: String
        var tags: [String]
        var ward: String
        var bed: String
        var threshold: Double
        var quantity: Int
        var active: Bool
        var copay: Double
        var graceDays: Int
        var status: BedBoardOverrideStatus

        init(code: String, name: String, tags: [String], ward: String, bed: String, threshold: Double, quantity: Int, active: Bool, copay: Double, graceDays: Int, status: BedBoardOverrideStatus) {
            self.code = code
            self.name = name
            self.tags = tags
            self.ward = ward
            self.bed = bed
            self.threshold = threshold
            self.quantity = quantity
            self.active = active
            self.copay = copay
            self.graceDays = graceDays
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

        func canMoveTo(_ next: BedBoardOverrideStatus) -> Bool {
            switch status {
            case .`open`:
                switch next {
                case .resolved, .archived:
                    return true
                default:
                    break
                }
                return false
            case .inReview:
                switch next {
                case .resolved, .reopened:
                    return true
                default:
                    break
                }
                return false
            case .resolved:
                switch next {
                case .reopened:
                    return true
                default:
                    break
                }
                return false
            case .reopened:
                return next == BedBoardOverrideStatus.archived
            default:
                break
            }
            return false
        }

        func moveTo(_ next: BedBoardOverrideStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("bed board override \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
        }

        func label() -> String {
            return "\(code): \(name)"
        }

        func hasTag(_ tag: String) -> Bool {
            for candidate in tags {
                if Kit.Text.normalize(candidate) == Kit.Text.normalize(tag) {
                    return true
                }
            }
            return false
        }

        func effectiveExposure() -> Double {
            return (copay * threshold * 100).rounded() / 100
        }

        func copyValue() -> BedBoardOverride {
            return BedBoardOverride(
                code: code,
                name: name,
                tags: tags,
                ward: ward,
                bed: bed,
                threshold: threshold,
                quantity: quantity,
                active: active,
                copay: copay,
                graceDays: graceDays,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(ward)
        }
    }

    /// Starts a bed board override in status open.
    static func newBedBoardOverride(_ code: String, name: String) -> BedBoardOverride {
        return BedBoardOverride(
            code: code,
            name: name,
            tags: [],
            ward: "",
            bed: "",
            threshold: 0.0,
            quantity: 0,
            active: false,
            copay: 0.0,
            graceDays: 0,
            status: BedBoardOverrideStatus.`open`
        )
    }
}
