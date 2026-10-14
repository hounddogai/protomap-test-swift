import AcmePlatform
import Foundation

extension CareManagement {
    /// Where a manual care gap allocation is in its life cycle.
    enum ManualCareGapAllocationStatus: String, CaseIterable {
        case idle
        case warming
        case ready
        case draining
        case stopped
    }

    /// The record of a manual care gap allocation and its current status.
    final class ManualCareGapAllocation {
        var code: String
        var title: String
        var country: String
        var specialty: String
        var copay: Double
        var description: String
        var status: ManualCareGapAllocationStatus

        init(code: String, title: String, country: String, specialty: String, copay: Double, description: String, status: ManualCareGapAllocationStatus) {
            self.code = code
            self.title = title
            self.country = country
            self.specialty = specialty
            self.copay = copay
            self.description = description
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

        func canMoveTo(_ next: ManualCareGapAllocationStatus) -> Bool {
            switch status {
            case .idle:
                switch next {
                case .warming, .draining:
                    return true
                default:
                    break
                }
                return false
            case .warming:
                return next == ManualCareGapAllocationStatus.ready || next == ManualCareGapAllocationStatus.draining
            case .ready:
                return next == ManualCareGapAllocationStatus.draining || next == ManualCareGapAllocationStatus.stopped
            case .draining:
                return next == ManualCareGapAllocationStatus.stopped
            default:
                break
            }
            return false
        }

        func moveTo(_ next: ManualCareGapAllocationStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("manual care gap allocation \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
        }

        func label() -> String {
            return "\(code) / \(title)"
        }

        func measuredValue() -> Double {
            return copay
        }

        func copyValue() -> ManualCareGapAllocation {
            return ManualCareGapAllocation(
                code: code,
                title: title,
                country: country,
                specialty: specialty,
                copay: copay,
                description: description,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(country)
        }
    }

    /// Starts a manual care gap allocation in status idle.
    static func newManualCareGapAllocation(_ code: String, title: String) -> ManualCareGapAllocation {
        return ManualCareGapAllocation(
            code: code,
            title: title,
            country: "",
            specialty: "",
            copay: 0.0,
            description: "",
            status: ManualCareGapAllocationStatus.idle
        )
    }
}
