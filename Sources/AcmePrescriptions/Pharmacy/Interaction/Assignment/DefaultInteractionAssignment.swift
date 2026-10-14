import AcmePlatform
import Foundation

extension Pharmacy {
    /// Where a default interaction assignment is in its life cycle.
    enum DefaultInteractionAssignmentStatus: String, CaseIterable {
        case idle
        case warming
        case ready
        case draining
        case stopped
    }

    /// The record of a default interaction assignment and its current status.
    final class DefaultInteractionAssignment {
        var code: String
        var name: String
        var maximum: Double
        var approved: Bool
        var country: String
        var dosageMg: Double
        var rate: Double
        var clinicianID: String
        var ownerID: String
        var score: Double
        var locale: String
        var status: DefaultInteractionAssignmentStatus

        init(code: String, name: String, maximum: Double, approved: Bool, country: String, dosageMg: Double, rate: Double, clinicianID: String, ownerID: String, score: Double, locale: String, status: DefaultInteractionAssignmentStatus) {
            self.code = code
            self.name = name
            self.maximum = maximum
            self.approved = approved
            self.country = country
            self.dosageMg = dosageMg
            self.rate = rate
            self.clinicianID = clinicianID
            self.ownerID = ownerID
            self.score = score
            self.locale = locale
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

        func canMoveTo(_ next: DefaultInteractionAssignmentStatus) -> Bool {
            switch status {
            case .idle:
                switch next {
                case .draining:
                    return true
                default:
                    break
                }
                return false
            case .warming:
                return next == DefaultInteractionAssignmentStatus.ready
            case .ready:
                return next == DefaultInteractionAssignmentStatus.draining
            case .draining:
                return next == DefaultInteractionAssignmentStatus.stopped
            default:
                break
            }
            return false
        }

        func moveTo(_ next: DefaultInteractionAssignmentStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("default interaction assignment \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
        }

        func label() -> String {
            return "\(code): \(name)"
        }

        func adjustedValue() -> Double {
            return (rate * score * 100).rounded() / 100
        }

        func copyValue() -> DefaultInteractionAssignment {
            return DefaultInteractionAssignment(
                code: code,
                name: name,
                maximum: maximum,
                approved: approved,
                country: country,
                dosageMg: dosageMg,
                rate: rate,
                clinicianID: clinicianID,
                ownerID: ownerID,
                score: score,
                locale: locale,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(country)
        }
    }

    /// Starts a default interaction assignment in status idle.
    static func newDefaultInteractionAssignment(_ code: String, name: String) -> DefaultInteractionAssignment {
        return DefaultInteractionAssignment(
            code: code,
            name: name,
            maximum: 0.0,
            approved: false,
            country: "",
            dosageMg: 0.0,
            rate: 0.0,
            clinicianID: "",
            ownerID: "",
            score: 0.0,
            locale: "",
            status: DefaultInteractionAssignmentStatus.idle
        )
    }
}
