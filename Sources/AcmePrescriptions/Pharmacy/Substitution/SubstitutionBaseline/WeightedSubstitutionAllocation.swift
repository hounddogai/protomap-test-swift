import AcmePlatform
import Foundation

extension Pharmacy {
    /// Where a weighted substitution allocation is in its life cycle.
    enum WeightedSubstitutionAllocationStatus: String, CaseIterable {
        case idle
        case warming
        case ready
        case draining
        case stopped
    }

    /// A weighted substitution allocation as the substitution team keeps it.
    final class WeightedSubstitutionAllocation {
        var code: String
        var title: String
        var discount: Double
        var source: String
        var startsAt: Int
        var patientRef: String
        var status: WeightedSubstitutionAllocationStatus

        init(code: String, title: String, discount: Double, source: String, startsAt: Int, patientRef: String, status: WeightedSubstitutionAllocationStatus) {
            self.code = code
            self.title = title
            self.discount = discount
            self.source = source
            self.startsAt = startsAt
            self.patientRef = patientRef
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

        func canMoveTo(_ next: WeightedSubstitutionAllocationStatus) -> Bool {
            switch status {
            case .idle:
                switch next {
                case .draining, .stopped:
                    return true
                default:
                    break
                }
                return false
            case .warming:
                switch next {
                case .ready, .draining:
                    return true
                default:
                    break
                }
                return false
            case .ready:
                return next == WeightedSubstitutionAllocationStatus.draining
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

        func moveTo(_ next: WeightedSubstitutionAllocationStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("weighted substitution allocation \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
            startsAt = Int(Date().timeIntervalSince1970)
        }

        func label() -> String {
            return "\("weighted substitution allocation") \(code)"
        }

        func adjustedExposure() -> Double {
            return (discount * Double(startsAt) * 100).rounded() / 100
        }

        func copyValue() -> WeightedSubstitutionAllocation {
            return WeightedSubstitutionAllocation(
                code: code,
                title: title,
                discount: discount,
                source: source,
                startsAt: startsAt,
                patientRef: patientRef,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(source)
        }
    }

    /// Starts a weighted substitution allocation in status idle.
    static func newWeightedSubstitutionAllocation(_ code: String, title: String) -> WeightedSubstitutionAllocation {
        return WeightedSubstitutionAllocation(
            code: code,
            title: title,
            discount: 0.0,
            source: "",
            startsAt: 0,
            patientRef: "",
            status: WeightedSubstitutionAllocationStatus.idle
        )
    }
}
