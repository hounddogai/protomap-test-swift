import AcmePlatform
import Foundation

extension Pharmacy {
    /// Where a capped substitution baseline is in its life cycle.
    enum CappedSubstitutionBaselineStatus: String, CaseIterable {
        case idle
        case warming
        case ready
        case draining
        case stopped
    }

    /// One capped substitution baseline, with what the planners need to act on it.
    final class CappedSubstitutionBaseline {
        var code: String
        var name: String
        var updatedAt: Int
        var capacity: Int
        var ratio: Double
        var score: Double
        var country: String
        var phone: String
        var notes: String
        var archived: Bool
        var bed: String
        var status: CappedSubstitutionBaselineStatus

        init(code: String, name: String, updatedAt: Int, capacity: Int, ratio: Double, score: Double, country: String, phone: String, notes: String, archived: Bool, bed: String, status: CappedSubstitutionBaselineStatus) {
            self.code = code
            self.name = name
            self.updatedAt = updatedAt
            self.capacity = capacity
            self.ratio = ratio
            self.score = score
            self.country = country
            self.phone = phone
            self.notes = notes
            self.archived = archived
            self.bed = bed
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

        func canMoveTo(_ next: CappedSubstitutionBaselineStatus) -> Bool {
            switch status {
            case .idle:
                return next == CappedSubstitutionBaselineStatus.warming || next == CappedSubstitutionBaselineStatus.ready
            case .warming:
                return next == CappedSubstitutionBaselineStatus.ready || next == CappedSubstitutionBaselineStatus.stopped
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

        func moveTo(_ next: CappedSubstitutionBaselineStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("capped substitution baseline \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
            updatedAt = Int(Date().timeIntervalSince1970)
        }

        func label() -> String {
            return "\("capped substitution baseline") \(code)"
        }

        func projectedLoad() -> Double {
            return ((score + Double(capacity)) * 100).rounded() / 100
        }

        func copyValue() -> CappedSubstitutionBaseline {
            return CappedSubstitutionBaseline(
                code: code,
                name: name,
                updatedAt: updatedAt,
                capacity: capacity,
                ratio: ratio,
                score: score,
                country: country,
                phone: phone,
                notes: notes,
                archived: archived,
                bed: bed,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(country)
        }
    }

    /// Starts a capped substitution baseline in status idle.
    static func newCappedSubstitutionBaseline(_ code: String, name: String) -> CappedSubstitutionBaseline {
        return CappedSubstitutionBaseline(
            code: code,
            name: name,
            updatedAt: 0,
            capacity: 0,
            ratio: 0.0,
            score: 0.0,
            country: "",
            phone: "",
            notes: "",
            archived: false,
            bed: "",
            status: CappedSubstitutionBaselineStatus.idle
        )
    }
}
