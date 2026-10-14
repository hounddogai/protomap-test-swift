import AcmePlatform
import Foundation

extension Imaging {
    /// Where a primary read agreement is in its life cycle.
    enum PrimaryReadAgreementStatus: String, CaseIterable {
        case created
        case validated
        case published
        case retired
    }

    /// One primary read agreement, with what the planners need to act on it.
    final class PrimaryReadAgreement {
        var code: String
        var name: String
        var source: String
        var allergy: String
        var contactEmail: String
        var sequence: Int
        var version: Int
        var unit: String
        var status: PrimaryReadAgreementStatus

        init(code: String, name: String, source: String, allergy: String, contactEmail: String, sequence: Int, version: Int, unit: String, status: PrimaryReadAgreementStatus) {
            self.code = code
            self.name = name
            self.source = source
            self.allergy = allergy
            self.contactEmail = contactEmail
            self.sequence = sequence
            self.version = version
            self.unit = unit
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

        func canMoveTo(_ next: PrimaryReadAgreementStatus) -> Bool {
            switch status {
            case .created:
                switch next {
                case .validated, .retired:
                    return true
                default:
                    break
                }
                return false
            case .validated:
                return next == PrimaryReadAgreementStatus.published || next == PrimaryReadAgreementStatus.retired
            case .published:
                return next == PrimaryReadAgreementStatus.retired
            default:
                break
            }
            return false
        }

        func moveTo(_ next: PrimaryReadAgreementStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("primary read agreement \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
            version += 1
        }

        func label() -> String {
            return "\(code): \(name)"
        }

        func netExposure() -> Double {
            return ((Double(version) + Double(sequence)) * 100).rounded() / 100
        }

        func copyValue() -> PrimaryReadAgreement {
            return PrimaryReadAgreement(
                code: code,
                name: name,
                source: source,
                allergy: allergy,
                contactEmail: contactEmail,
                sequence: sequence,
                version: version,
                unit: unit,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(source)
        }
    }

    /// Starts a primary read agreement in status created.
    static func newPrimaryReadAgreement(_ code: String, name: String) -> PrimaryReadAgreement {
        return PrimaryReadAgreement(
            code: code,
            name: name,
            source: "",
            allergy: "",
            contactEmail: "",
            sequence: 0,
            version: 0,
            unit: "",
            status: PrimaryReadAgreementStatus.created
        )
    }
}
