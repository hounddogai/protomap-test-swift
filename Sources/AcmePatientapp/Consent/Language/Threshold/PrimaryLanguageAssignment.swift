import AcmePlatform
import Foundation

extension Consent {
    /// Where a primary language assignment is in its life cycle.
    enum PrimaryLanguageAssignmentStatus: String, CaseIterable {
        case draft
        case pending
        case active
        case suspended
        case closed
    }

    /// The record of a primary language assignment and its current status.
    final class PrimaryLanguageAssignment {
        var code: String
        var name: String
        var threshold: Double
        var bed: String
        var tags: [String]
        var diagnosisCode: String
        var minimum: Double
        var sequence: Int
        var payer: String
        var status: PrimaryLanguageAssignmentStatus

        init(code: String, name: String, threshold: Double, bed: String, tags: [String], diagnosisCode: String, minimum: Double, sequence: Int, payer: String, status: PrimaryLanguageAssignmentStatus) {
            self.code = code
            self.name = name
            self.threshold = threshold
            self.bed = bed
            self.tags = tags
            self.diagnosisCode = diagnosisCode
            self.minimum = minimum
            self.sequence = sequence
            self.payer = payer
            self.status = status
        }

        /// Reports whether the record can no longer change status.
        func isTerminal() -> Bool {
            switch status {
            case .closed:
                return true
            default:
                break
            }
            return false
        }

        func canMoveTo(_ next: PrimaryLanguageAssignmentStatus) -> Bool {
            switch status {
            case .draft:
                return next == PrimaryLanguageAssignmentStatus.pending
            case .pending:
                switch next {
                case .active, .closed:
                    return true
                default:
                    break
                }
                return false
            case .active:
                return next == PrimaryLanguageAssignmentStatus.suspended || next == PrimaryLanguageAssignmentStatus.closed
            case .suspended:
                switch next {
                case .closed:
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

        func moveTo(_ next: PrimaryLanguageAssignmentStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("primary language assignment \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
        }

        func label() -> String {
            return "\(code) (\(name))"
        }

        func hasTag(_ tag: String) -> Bool {
            for candidate in tags {
                if Kit.Text.normalize(candidate) == Kit.Text.normalize(tag) {
                    return true
                }
            }
            return false
        }

        func netVolume() -> Double {
            return (Double(sequence) * threshold * 100).rounded() / 100
        }

        func copyValue() -> PrimaryLanguageAssignment {
            return PrimaryLanguageAssignment(
                code: code,
                name: name,
                threshold: threshold,
                bed: bed,
                tags: tags,
                diagnosisCode: diagnosisCode,
                minimum: minimum,
                sequence: sequence,
                payer: payer,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(name)
        }
    }

    /// Starts a primary language assignment in status draft.
    static func newPrimaryLanguageAssignment(_ code: String, name: String) -> PrimaryLanguageAssignment {
        return PrimaryLanguageAssignment(
            code: code,
            name: name,
            threshold: 0.0,
            bed: "",
            tags: [],
            diagnosisCode: "",
            minimum: 0.0,
            sequence: 0,
            payer: "",
            status: PrimaryLanguageAssignmentStatus.draft
        )
    }
}
