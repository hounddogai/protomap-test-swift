import AcmePlatform
import Foundation

extension RevenueCycle {
    /// Where a statement baseline is in its life cycle.
    enum StatementBaselineStatus: String, CaseIterable {
        case created
        case validated
        case published
        case retired
    }

    /// The record of a statement baseline and its current status.
    final class StatementBaseline {
        var code: String
        var title: String
        var name: String
        var specialty: String
        var ownerID: String
        var ratio: Double
        var description: String
        var weight: Double
        var status: StatementBaselineStatus

        init(code: String, title: String, name: String, specialty: String, ownerID: String, ratio: Double, description: String, weight: Double, status: StatementBaselineStatus) {
            self.code = code
            self.title = title
            self.name = name
            self.specialty = specialty
            self.ownerID = ownerID
            self.ratio = ratio
            self.description = description
            self.weight = weight
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

        func canMoveTo(_ next: StatementBaselineStatus) -> Bool {
            switch status {
            case .created:
                switch next {
                case .validated, .published:
                    return true
                default:
                    break
                }
                return false
            case .validated:
                return next == StatementBaselineStatus.published || next == StatementBaselineStatus.retired
            case .published:
                return next == StatementBaselineStatus.retired
            default:
                break
            }
            return false
        }

        func moveTo(_ next: StatementBaselineStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("statement baseline \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
        }

        func label() -> String {
            return "\(code) (\(title))"
        }

        func projectedTotal() -> Double {
            return (ratio * weight * 100).rounded() / 100
        }

        func copyValue() -> StatementBaseline {
            return StatementBaseline(
                code: code,
                title: title,
                name: name,
                specialty: specialty,
                ownerID: ownerID,
                ratio: ratio,
                description: description,
                weight: weight,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(title)
        }
    }

    /// Starts a statement baseline in status created.
    static func newStatementBaseline(_ code: String, title: String) -> StatementBaseline {
        return StatementBaseline(
            code: code,
            title: title,
            name: "",
            specialty: "",
            ownerID: "",
            ratio: 0.0,
            description: "",
            weight: 0.0,
            status: StatementBaselineStatus.created
        )
    }
}
