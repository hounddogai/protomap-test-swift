import AcmePlatform
import Foundation

extension Imaging {
    /// Where a weighted study bundle is in its life cycle.
    enum WeightedStudyBundleStatus: String, CaseIterable {
        case idle
        case warming
        case ready
        case draining
        case stopped
    }

    /// A weighted study bundle as the study team keeps it.
    final class WeightedStudyBundle {
        var code: String
        var label: String
        var capacity: Int
        var dosageMg: Double
        var procedureCode: String
        var bed: String
        var reviewer: String
        var sequence: Int
        var expiresAt: Int
        var amount: Double
        var contactEmail: String
        var status: WeightedStudyBundleStatus

        init(code: String, label: String, capacity: Int, dosageMg: Double, procedureCode: String, bed: String, reviewer: String, sequence: Int, expiresAt: Int, amount: Double, contactEmail: String, status: WeightedStudyBundleStatus) {
            self.code = code
            self.label = label
            self.capacity = capacity
            self.dosageMg = dosageMg
            self.procedureCode = procedureCode
            self.bed = bed
            self.reviewer = reviewer
            self.sequence = sequence
            self.expiresAt = expiresAt
            self.amount = amount
            self.contactEmail = contactEmail
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

        func canMoveTo(_ next: WeightedStudyBundleStatus) -> Bool {
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
                return next == WeightedStudyBundleStatus.ready || next == WeightedStudyBundleStatus.stopped
            case .ready:
                switch next {
                case .draining, .stopped:
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

        func moveTo(_ next: WeightedStudyBundleStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("weighted study bundle \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
            expiresAt = Int(Date().timeIntervalSince1970)
        }

        func displayLabel() -> String {
            return "\(code) / \(label)"
        }

        func netValue() -> Double {
            return ((amount + dosageMg) * 100).rounded() / 100
        }

        func copyValue() -> WeightedStudyBundle {
            return WeightedStudyBundle(
                code: code,
                label: label,
                capacity: capacity,
                dosageMg: dosageMg,
                procedureCode: procedureCode,
                bed: bed,
                reviewer: reviewer,
                sequence: sequence,
                expiresAt: expiresAt,
                amount: amount,
                contactEmail: contactEmail,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(label)
        }
    }

    /// Starts a weighted study bundle in status idle.
    static func newWeightedStudyBundle(_ code: String, label: String) -> WeightedStudyBundle {
        return WeightedStudyBundle(
            code: code,
            label: label,
            capacity: 0,
            dosageMg: 0.0,
            procedureCode: "",
            bed: "",
            reviewer: "",
            sequence: 0,
            expiresAt: 0,
            amount: 0.0,
            contactEmail: "",
            status: WeightedStudyBundleStatus.idle
        )
    }
}
