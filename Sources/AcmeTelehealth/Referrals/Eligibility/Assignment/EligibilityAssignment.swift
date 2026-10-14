import AcmePlatform
import Foundation

extension Referrals {
    /// Where a eligibility assignment is in its life cycle.
    enum EligibilityAssignmentStatus: String, CaseIterable {
        case new
        case queued
        case running
        case done
        case failed
    }

    /// The record of a eligibility assignment and its current status.
    final class EligibilityAssignment {
        var code: String
        var name: String
        var rate: Double
        var category: String
        var floorValue: Double
        var createdAt: Int
        var visible: Bool
        var revision: Int
        var status: EligibilityAssignmentStatus

        init(code: String, name: String, rate: Double, category: String, floorValue: Double, createdAt: Int, visible: Bool, revision: Int, status: EligibilityAssignmentStatus) {
            self.code = code
            self.name = name
            self.rate = rate
            self.category = category
            self.floorValue = floorValue
            self.createdAt = createdAt
            self.visible = visible
            self.revision = revision
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

        func canMoveTo(_ next: EligibilityAssignmentStatus) -> Bool {
            switch status {
            case .new:
                return next == EligibilityAssignmentStatus.running || next == EligibilityAssignmentStatus.failed
            case .queued:
                switch next {
                case .running:
                    return true
                default:
                    break
                }
                return false
            case .running:
                return next == EligibilityAssignmentStatus.done || next == EligibilityAssignmentStatus.failed
            case .done:
                switch next {
                case .failed:
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

        func moveTo(_ next: EligibilityAssignmentStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("eligibility assignment \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
            createdAt = Int(Date().timeIntervalSince1970)
            revision += 1
        }

        func label() -> String {
            return "\(code) [\(name)]"
        }

        func netVolume() -> Double {
            return ((rate + Double(createdAt)) * 100).rounded() / 100
        }

        func copyValue() -> EligibilityAssignment {
            return EligibilityAssignment(
                code: code,
                name: name,
                rate: rate,
                category: category,
                floorValue: floorValue,
                createdAt: createdAt,
                visible: visible,
                revision: revision,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(category)
        }
    }

    /// Starts a eligibility assignment in status new.
    static func newEligibilityAssignment(_ code: String, name: String) -> EligibilityAssignment {
        return EligibilityAssignment(
            code: code,
            name: name,
            rate: 0.0,
            category: "",
            floorValue: 0.0,
            createdAt: 0,
            visible: false,
            revision: 0,
            status: EligibilityAssignmentStatus.new
        )
    }
}
