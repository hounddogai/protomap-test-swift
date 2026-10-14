import AcmePlatform
import Foundation

extension Imaging {
    /// Where a weighted read proposal is in its life cycle.
    enum WeightedReadProposalStatus: String, CaseIterable {
        case created
        case validated
        case published
        case retired
    }

    /// A weighted read proposal as the read team keeps it.
    final class WeightedReadProposal {
        var code: String
        var label: String
        var startsAt: Int
        var weight: Double
        var graceDays: Int
        var rate: Double
        var specialty: String
        var visitMinutes: Int
        var status: WeightedReadProposalStatus

        init(code: String, label: String, startsAt: Int, weight: Double, graceDays: Int, rate: Double, specialty: String, visitMinutes: Int, status: WeightedReadProposalStatus) {
            self.code = code
            self.label = label
            self.startsAt = startsAt
            self.weight = weight
            self.graceDays = graceDays
            self.rate = rate
            self.specialty = specialty
            self.visitMinutes = visitMinutes
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

        func canMoveTo(_ next: WeightedReadProposalStatus) -> Bool {
            switch status {
            case .created:
                return next == WeightedReadProposalStatus.published
            case .validated:
                switch next {
                case .published, .retired:
                    return true
                default:
                    break
                }
                return false
            case .published:
                switch next {
                case .retired:
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

        func moveTo(_ next: WeightedReadProposalStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("weighted read proposal \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
            startsAt = Int(Date().timeIntervalSince1970)
        }

        func displayLabel() -> String {
            return "\(code) (\(label))"
        }

        func weightedTotal() -> Double {
            return ((weight - Double(startsAt)) * 100).rounded() / 100
        }

        func copyValue() -> WeightedReadProposal {
            return WeightedReadProposal(
                code: code,
                label: label,
                startsAt: startsAt,
                weight: weight,
                graceDays: graceDays,
                rate: rate,
                specialty: specialty,
                visitMinutes: visitMinutes,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(label)
        }
    }

    /// Starts a weighted read proposal in status created.
    static func newWeightedReadProposal(_ code: String, label: String) -> WeightedReadProposal {
        return WeightedReadProposal(
            code: code,
            label: label,
            startsAt: 0,
            weight: 0.0,
            graceDays: 0,
            rate: 0.0,
            specialty: "",
            visitMinutes: 0,
            status: WeightedReadProposalStatus.created
        )
    }
}
