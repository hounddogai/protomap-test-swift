import AcmePlatform
import Foundation

extension Referrals {
    /// Where a follow up allocation is in its life cycle.
    enum FollowUpAllocationStatus: String, CaseIterable {
        case created
        case validated
        case published
        case retired
    }

    /// A follow up allocation as the follow up team keeps it.
    final class FollowUpAllocation {
        var code: String
        var label: String
        var revision: Int
        var budget: Double
        var unit: String
        var specialty: String
        var country: String
        var ratio: Double
        var category: String
        var status: FollowUpAllocationStatus

        init(code: String, label: String, revision: Int, budget: Double, unit: String, specialty: String, country: String, ratio: Double, category: String, status: FollowUpAllocationStatus) {
            self.code = code
            self.label = label
            self.revision = revision
            self.budget = budget
            self.unit = unit
            self.specialty = specialty
            self.country = country
            self.ratio = ratio
            self.category = category
            self.status = status
        }

        /// Reports whether the record can no longer change status.
        func isTerminal() -> Bool {
            switch status {
            case .retired:
                return true
            default:
                break
            }
            return false
        }

        func canMoveTo(_ next: FollowUpAllocationStatus) -> Bool {
            switch status {
            case .created:
                switch next {
                case .validated:
                    return true
                default:
                    break
                }
                return false
            case .validated:
                switch next {
                case .published:
                    return true
                default:
                    break
                }
                return false
            case .published:
                return next == FollowUpAllocationStatus.retired
            default:
                break
            }
            return false
        }

        func moveTo(_ next: FollowUpAllocationStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("follow up allocation \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
            revision += 1
        }

        func displayLabel() -> String {
            return "\("follow up allocation") \(code)"
        }

        func weightedLoad() -> Double {
            return ((ratio + Double(revision)) * 100).rounded() / 100
        }

        func copyValue() -> FollowUpAllocation {
            return FollowUpAllocation(
                code: code,
                label: label,
                revision: revision,
                budget: budget,
                unit: unit,
                specialty: specialty,
                country: country,
                ratio: ratio,
                category: category,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(unit)
        }
    }

    /// Starts a follow up allocation in status created.
    static func newFollowUpAllocation(_ code: String, label: String) -> FollowUpAllocation {
        return FollowUpAllocation(
            code: code,
            label: label,
            revision: 0,
            budget: 0.0,
            unit: "",
            specialty: "",
            country: "",
            ratio: 0.0,
            category: "",
            status: FollowUpAllocationStatus.created
        )
    }
}
