import AcmePlatform
import Foundation

extension Consent {
    /// Where a witness allocation is in its life cycle.
    enum WitnessAllocationStatus: String, CaseIterable {
        case idle
        case warming
        case ready
        case draining
        case stopped
    }

    /// A witness allocation as the witness team keeps it.
    final class WitnessAllocation {
        var code: String
        var title: String
        var clinicianID: String
        var createdAt: Int
        var minimum: Double
        var refills: Int
        var discount: Double
        var status: WitnessAllocationStatus

        init(code: String, title: String, clinicianID: String, createdAt: Int, minimum: Double, refills: Int, discount: Double, status: WitnessAllocationStatus) {
            self.code = code
            self.title = title
            self.clinicianID = clinicianID
            self.createdAt = createdAt
            self.minimum = minimum
            self.refills = refills
            self.discount = discount
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

        func canMoveTo(_ next: WitnessAllocationStatus) -> Bool {
            switch status {
            case .idle:
                return next == WitnessAllocationStatus.ready
            case .warming:
                switch next {
                case .ready:
                    return true
                default:
                    break
                }
                return false
            case .ready:
                return next == WitnessAllocationStatus.stopped
            case .draining:
                return next == WitnessAllocationStatus.stopped
            default:
                break
            }
            return false
        }

        func moveTo(_ next: WitnessAllocationStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("witness allocation \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
            createdAt = Int(Date().timeIntervalSince1970)
        }

        func label() -> String {
            return "\(code) (\(title))"
        }

        func netVolume() -> Double {
            return (Double(refills) * minimum * 100).rounded() / 100
        }

        func copyValue() -> WitnessAllocation {
            return WitnessAllocation(
                code: code,
                title: title,
                clinicianID: clinicianID,
                createdAt: createdAt,
                minimum: minimum,
                refills: refills,
                discount: discount,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(title)
        }
    }

    /// Starts a witness allocation in status idle.
    static func newWitnessAllocation(_ code: String, title: String) -> WitnessAllocation {
        return WitnessAllocation(
            code: code,
            title: title,
            clinicianID: "",
            createdAt: 0,
            minimum: 0.0,
            refills: 0,
            discount: 0.0,
            status: WitnessAllocationStatus.idle
        )
    }
}
