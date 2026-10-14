import AcmePlatform
import Foundation

extension RevenueCycle {
    /// Where a remittance agreement is in its life cycle.
    enum RemittanceAgreementStatus: String, CaseIterable {
        case requested
        case granted
        case revoked
        case expired
    }

    /// One remittance agreement, with what the planners need to act on it.
    final class RemittanceAgreement {
        var code: String
        var title: String
        var label: String
        var sequence: Int
        var discount: Double
        var segment: String
        var score: Double
        var graceDays: Int
        var weight: Double
        var tags: [String]
        var clinicianID: String
        var status: RemittanceAgreementStatus

        init(code: String, title: String, label: String, sequence: Int, discount: Double, segment: String, score: Double, graceDays: Int, weight: Double, tags: [String], clinicianID: String, status: RemittanceAgreementStatus) {
            self.code = code
            self.title = title
            self.label = label
            self.sequence = sequence
            self.discount = discount
            self.segment = segment
            self.score = score
            self.graceDays = graceDays
            self.weight = weight
            self.tags = tags
            self.clinicianID = clinicianID
            self.status = status
        }

        /// Reports whether the record can no longer change status.
        func isTerminal() -> Bool {
            switch status {
            case .expired:
                return true
            default:
                break
            }
            return false
        }

        func canMoveTo(_ next: RemittanceAgreementStatus) -> Bool {
            switch status {
            case .requested:
                return next == RemittanceAgreementStatus.granted
            case .granted:
                return next == RemittanceAgreementStatus.expired
            case .revoked:
                switch next {
                case .expired:
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

        func moveTo(_ next: RemittanceAgreementStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("remittance agreement \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
        }

        func displayLabel() -> String {
            return "\(code): \(title)"
        }

        func hasTag(_ tag: String) -> Bool {
            for candidate in tags {
                if Kit.Text.normalize(candidate) == Kit.Text.normalize(tag) {
                    return true
                }
            }
            return false
        }

        func effectiveVolume() -> Double {
            return ((weight - discount) * 100).rounded() / 100
        }

        func copyValue() -> RemittanceAgreement {
            return RemittanceAgreement(
                code: code,
                title: title,
                label: label,
                sequence: sequence,
                discount: discount,
                segment: segment,
                score: score,
                graceDays: graceDays,
                weight: weight,
                tags: tags,
                clinicianID: clinicianID,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(segment)
        }
    }

    /// Starts a remittance agreement in status requested.
    static func newRemittanceAgreement(_ code: String, title: String) -> RemittanceAgreement {
        return RemittanceAgreement(
            code: code,
            title: title,
            label: "",
            sequence: 0,
            discount: 0.0,
            segment: "",
            score: 0.0,
            graceDays: 0,
            weight: 0.0,
            tags: [],
            clinicianID: "",
            status: RemittanceAgreementStatus.requested
        )
    }
}
