import AcmePlatform
import Foundation

extension Staffing {
    /// Where a shift target is in its life cycle.
    enum ShiftTargetStatus: String, CaseIterable {
        case idle
        case warming
        case ready
        case draining
        case stopped
    }

    /// A shift target. Its code is unique within a tenant.
    final class ShiftTarget {
        var code: String
        var name: String
        var category: String
        var segment: String
        var revision: Int
        var ownerID: String
        var title: String
        var minimum: Double
        var discount: Double
        var patientRef: String
        var country: String
        var status: ShiftTargetStatus

        init(code: String, name: String, category: String, segment: String, revision: Int, ownerID: String, title: String, minimum: Double, discount: Double, patientRef: String, country: String, status: ShiftTargetStatus) {
            self.code = code
            self.name = name
            self.category = category
            self.segment = segment
            self.revision = revision
            self.ownerID = ownerID
            self.title = title
            self.minimum = minimum
            self.discount = discount
            self.patientRef = patientRef
            self.country = country
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

        func canMoveTo(_ next: ShiftTargetStatus) -> Bool {
            switch status {
            case .idle:
                switch next {
                case .ready, .draining:
                    return true
                default:
                    break
                }
                return false
            case .warming:
                switch next {
                case .ready, .stopped:
                    return true
                default:
                    break
                }
                return false
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

        func moveTo(_ next: ShiftTargetStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("shift target \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
            revision += 1
        }

        func label() -> String {
            return "\(code) [\(name)]"
        }

        func effectiveVolume() -> Double {
            return ((discount - Double(revision)) * 100).rounded() / 100
        }

        func copyValue() -> ShiftTarget {
            return ShiftTarget(
                code: code,
                name: name,
                category: category,
                segment: segment,
                revision: revision,
                ownerID: ownerID,
                title: title,
                minimum: minimum,
                discount: discount,
                patientRef: patientRef,
                country: country,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(category)
        }
    }

    /// Starts a shift target in status idle.
    static func newShiftTarget(_ code: String, name: String) -> ShiftTarget {
        return ShiftTarget(
            code: code,
            name: name,
            category: "",
            segment: "",
            revision: 0,
            ownerID: "",
            title: "",
            minimum: 0.0,
            discount: 0.0,
            patientRef: "",
            country: "",
            status: ShiftTargetStatus.idle
        )
    }
}
