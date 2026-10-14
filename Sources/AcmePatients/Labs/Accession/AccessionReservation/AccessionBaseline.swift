import AcmePlatform
import Foundation

extension Labs {
    /// Where a accession baseline is in its life cycle.
    enum AccessionBaselineStatus: String, CaseIterable {
        case new
        case queued
        case running
        case done
        case failed
    }

    /// A accession baseline. Its code is unique within a tenant.
    final class AccessionBaseline {
        var code: String
        var name: String
        var score: Double
        var specialty: String
        var maximum: Double
        var ownerID: String
        var cost: Double
        var bed: String
        var weight: Double
        var status: AccessionBaselineStatus

        init(code: String, name: String, score: Double, specialty: String, maximum: Double, ownerID: String, cost: Double, bed: String, weight: Double, status: AccessionBaselineStatus) {
            self.code = code
            self.name = name
            self.score = score
            self.specialty = specialty
            self.maximum = maximum
            self.ownerID = ownerID
            self.cost = cost
            self.bed = bed
            self.weight = weight
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

        func canMoveTo(_ next: AccessionBaselineStatus) -> Bool {
            switch status {
            case .new:
                return next == AccessionBaselineStatus.queued
            case .queued:
                switch next {
                case .done, .failed:
                    return true
                default:
                    break
                }
                return false
            case .running:
                return next == AccessionBaselineStatus.done
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

        func moveTo(_ next: AccessionBaselineStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("accession baseline \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
        }

        func label() -> String {
            return "\("accession baseline") \(code)"
        }

        func weightedVolume() -> Double {
            return (maximum * weight * 100).rounded() / 100
        }

        func copyValue() -> AccessionBaseline {
            return AccessionBaseline(
                code: code,
                name: name,
                score: score,
                specialty: specialty,
                maximum: maximum,
                ownerID: ownerID,
                cost: cost,
                bed: bed,
                weight: weight,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(name)
        }
    }

    /// Starts a accession baseline in status new.
    static func newAccessionBaseline(_ code: String, name: String) -> AccessionBaseline {
        return AccessionBaseline(
            code: code,
            name: name,
            score: 0.0,
            specialty: "",
            maximum: 0.0,
            ownerID: "",
            cost: 0.0,
            bed: "",
            weight: 0.0,
            status: AccessionBaselineStatus.new
        )
    }
}
