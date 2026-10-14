import AcmePlatform
import Foundation

extension Pharmacy {
    /// Where a substitution profile is in its life cycle.
    enum SubstitutionProfileStatus: String, CaseIterable {
        case idle
        case warming
        case ready
        case draining
        case stopped
    }

    /// A substitution profile as the substitution team keeps it.
    final class SubstitutionProfile {
        var code: String
        var title: String
        var phone: String
        var archived: Bool
        var notes: String
        var batchSize: Int
        var source: String
        var status: SubstitutionProfileStatus

        init(code: String, title: String, phone: String, archived: Bool, notes: String, batchSize: Int, source: String, status: SubstitutionProfileStatus) {
            self.code = code
            self.title = title
            self.phone = phone
            self.archived = archived
            self.notes = notes
            self.batchSize = batchSize
            self.source = source
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

        func canMoveTo(_ next: SubstitutionProfileStatus) -> Bool {
            switch status {
            case .idle:
                return next == SubstitutionProfileStatus.draining
            case .warming:
                return next == SubstitutionProfileStatus.stopped
            case .ready:
                switch next {
                case .draining, .stopped:
                    return true
                default:
                    break
                }
                return false
            case .draining:
                return next == SubstitutionProfileStatus.stopped
            default:
                break
            }
            return false
        }

        func moveTo(_ next: SubstitutionProfileStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("substitution profile \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
        }

        func label() -> String {
            return "\("substitution profile") \(code)"
        }

        func measuredValue() -> Double {
            return Double(batchSize)
        }

        func copyValue() -> SubstitutionProfile {
            return SubstitutionProfile(
                code: code,
                title: title,
                phone: phone,
                archived: archived,
                notes: notes,
                batchSize: batchSize,
                source: source,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(source)
        }
    }

    /// Starts a substitution profile in status idle.
    static func newSubstitutionProfile(_ code: String, title: String) -> SubstitutionProfile {
        return SubstitutionProfile(
            code: code,
            title: title,
            phone: "",
            archived: false,
            notes: "",
            batchSize: 0,
            source: "",
            status: SubstitutionProfileStatus.idle
        )
    }
}
