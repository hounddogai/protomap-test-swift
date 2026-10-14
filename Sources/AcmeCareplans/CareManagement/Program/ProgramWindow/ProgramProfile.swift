import AcmePlatform
import Foundation

extension CareManagement {
    /// Where a program profile is in its life cycle.
    enum ProgramProfileStatus: String, CaseIterable {
        case `open`
        case inReview = "in_review"
        case resolved
        case reopened
        case archived
    }

    /// The record of a program profile and its current status.
    final class ProgramProfile {
        var code: String
        var label: String
        var procedureCode: String
        var externalRef: String
        var revision: Int
        var quantity: Int
        var description: String
        var weight: Double
        var contactEmail: String
        var ratio: Double
        var status: ProgramProfileStatus

        init(code: String, label: String, procedureCode: String, externalRef: String, revision: Int, quantity: Int, description: String, weight: Double, contactEmail: String, ratio: Double, status: ProgramProfileStatus) {
            self.code = code
            self.label = label
            self.procedureCode = procedureCode
            self.externalRef = externalRef
            self.revision = revision
            self.quantity = quantity
            self.description = description
            self.weight = weight
            self.contactEmail = contactEmail
            self.ratio = ratio
            self.status = status
        }

        /// Reports whether the record can no longer change status.
        func isTerminal() -> Bool {
            switch status {
            case .archived:
                return true
            default:
                break
            }
            return false
        }

        func canMoveTo(_ next: ProgramProfileStatus) -> Bool {
            switch status {
            case .`open`:
                return next == ProgramProfileStatus.inReview || next == ProgramProfileStatus.resolved
            case .inReview:
                switch next {
                case .reopened, .archived:
                    return true
                default:
                    break
                }
                return false
            case .resolved:
                switch next {
                case .reopened, .archived:
                    return true
                default:
                    break
                }
                return false
            case .reopened:
                return next == ProgramProfileStatus.archived
            default:
                break
            }
            return false
        }

        func moveTo(_ next: ProgramProfileStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("program profile \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
            revision += 1
        }

        func displayLabel() -> String {
            return "\(code) [\(label)]"
        }

        func projectedTotal() -> Double {
            return (weight * Double(quantity) * 100).rounded() / 100
        }

        func copyValue() -> ProgramProfile {
            return ProgramProfile(
                code: code,
                label: label,
                procedureCode: procedureCode,
                externalRef: externalRef,
                revision: revision,
                quantity: quantity,
                description: description,
                weight: weight,
                contactEmail: contactEmail,
                ratio: ratio,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(label)
        }
    }

    /// Starts a program profile in status open.
    static func newProgramProfile(_ code: String, label: String) -> ProgramProfile {
        return ProgramProfile(
            code: code,
            label: label,
            procedureCode: "",
            externalRef: "",
            revision: 0,
            quantity: 0,
            description: "",
            weight: 0.0,
            contactEmail: "",
            ratio: 0.0,
            status: ProgramProfileStatus.`open`
        )
    }
}
