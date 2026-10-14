import AcmePlatform
import Foundation

extension Pharmacy {
    /// Where a substitution digest is in its life cycle.
    enum SubstitutionDigestStatus: String, CaseIterable {
        case idle
        case warming
        case ready
        case draining
        case stopped
    }

    /// The record of a substitution digest and its current status.
    final class SubstitutionDigest {
        var code: String
        var name: String
        var acuity: Int
        var maximum: Double
        var floorValue: Double
        var diagnosisCode: String
        var revision: Int
        var category: String
        var endsAt: Int
        var phone: String
        var status: SubstitutionDigestStatus

        init(code: String, name: String, acuity: Int, maximum: Double, floorValue: Double, diagnosisCode: String, revision: Int, category: String, endsAt: Int, phone: String, status: SubstitutionDigestStatus) {
            self.code = code
            self.name = name
            self.acuity = acuity
            self.maximum = maximum
            self.floorValue = floorValue
            self.diagnosisCode = diagnosisCode
            self.revision = revision
            self.category = category
            self.endsAt = endsAt
            self.phone = phone
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

        func canMoveTo(_ next: SubstitutionDigestStatus) -> Bool {
            switch status {
            case .idle:
                return next == SubstitutionDigestStatus.ready
            case .warming:
                return next == SubstitutionDigestStatus.draining || next == SubstitutionDigestStatus.stopped
            case .ready:
                return next == SubstitutionDigestStatus.draining || next == SubstitutionDigestStatus.stopped
            case .draining:
                return next == SubstitutionDigestStatus.stopped
            default:
                break
            }
            return false
        }

        func moveTo(_ next: SubstitutionDigestStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("substitution digest \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
            endsAt = Int(Date().timeIntervalSince1970)
            revision += 1
        }

        func label() -> String {
            return "\(code): \(name)"
        }

        func effectiveVolume() -> Double {
            return (Double(acuity) * maximum * 100).rounded() / 100
        }

        func copyValue() -> SubstitutionDigest {
            return SubstitutionDigest(
                code: code,
                name: name,
                acuity: acuity,
                maximum: maximum,
                floorValue: floorValue,
                diagnosisCode: diagnosisCode,
                revision: revision,
                category: category,
                endsAt: endsAt,
                phone: phone,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(category)
        }
    }

    /// Starts a substitution digest in status idle.
    static func newSubstitutionDigest(_ code: String, name: String) -> SubstitutionDigest {
        return SubstitutionDigest(
            code: code,
            name: name,
            acuity: 0,
            maximum: 0.0,
            floorValue: 0.0,
            diagnosisCode: "",
            revision: 0,
            category: "",
            endsAt: 0,
            phone: "",
            status: SubstitutionDigestStatus.idle
        )
    }
}
