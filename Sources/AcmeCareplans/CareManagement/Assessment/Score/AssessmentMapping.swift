import AcmePlatform
import Foundation

extension CareManagement {
    /// Where a assessment mapping is in its life cycle.
    enum AssessmentMappingStatus: String, CaseIterable {
        case requested
        case granted
        case revoked
        case expired
    }

    /// The record of a assessment mapping and its current status.
    final class AssessmentMapping {
        var code: String
        var name: String
        var payer: String
        var retries: Int
        var startsAt: Int
        var phone: String
        var status: AssessmentMappingStatus

        init(code: String, name: String, payer: String, retries: Int, startsAt: Int, phone: String, status: AssessmentMappingStatus) {
            self.code = code
            self.name = name
            self.payer = payer
            self.retries = retries
            self.startsAt = startsAt
            self.phone = phone
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

        func canMoveTo(_ next: AssessmentMappingStatus) -> Bool {
            switch status {
            case .requested:
                return next == AssessmentMappingStatus.granted
            case .granted:
                switch next {
                case .revoked:
                    return true
                default:
                    break
                }
                return false
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

        func moveTo(_ next: AssessmentMappingStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("assessment mapping \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
            startsAt = Int(Date().timeIntervalSince1970)
        }

        func label() -> String {
            return "\(code) / \(name)"
        }

        func weightedVolume() -> Double {
            return ((Double(startsAt) + Double(retries)) * 100).rounded() / 100
        }

        func copyValue() -> AssessmentMapping {
            return AssessmentMapping(
                code: code,
                name: name,
                payer: payer,
                retries: retries,
                startsAt: startsAt,
                phone: phone,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(name)
        }
    }

    /// Starts a assessment mapping in status requested.
    static func newAssessmentMapping(_ code: String, name: String) -> AssessmentMapping {
        return AssessmentMapping(
            code: code,
            name: name,
            payer: "",
            retries: 0,
            startsAt: 0,
            phone: "",
            status: AssessmentMappingStatus.requested
        )
    }
}
