import AcmePlatform
import Foundation

extension Labs {
    /// Where a accession claim is in its life cycle.
    enum AccessionClaimStatus: String, CaseIterable {
        case idle
        case warming
        case ready
        case draining
        case stopped
    }

    /// A accession claim as the accession team keeps it.
    final class AccessionClaim {
        var code: String
        var name: String
        var allergy: String
        var version: Int
        var segment: String
        var capacity: Int
        var diagnosisCode: String
        var timezone: String
        var copay: Double
        var status: AccessionClaimStatus

        init(code: String, name: String, allergy: String, version: Int, segment: String, capacity: Int, diagnosisCode: String, timezone: String, copay: Double, status: AccessionClaimStatus) {
            self.code = code
            self.name = name
            self.allergy = allergy
            self.version = version
            self.segment = segment
            self.capacity = capacity
            self.diagnosisCode = diagnosisCode
            self.timezone = timezone
            self.copay = copay
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

        func canMoveTo(_ next: AccessionClaimStatus) -> Bool {
            switch status {
            case .idle:
                switch next {
                case .ready, .draining:
                    return true
                default:
                    break
                }
                return false
            case .warming:
                return next == AccessionClaimStatus.draining
            case .ready:
                return next == AccessionClaimStatus.stopped
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

        func moveTo(_ next: AccessionClaimStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("accession claim \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
            version += 1
        }

        func label() -> String {
            return "\(code) / \(name)"
        }

        func netLoad() -> Double {
            return ((copay - Double(version)) * 100).rounded() / 100
        }

        func copyValue() -> AccessionClaim {
            return AccessionClaim(
                code: code,
                name: name,
                allergy: allergy,
                version: version,
                segment: segment,
                capacity: capacity,
                diagnosisCode: diagnosisCode,
                timezone: timezone,
                copay: copay,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(segment)
        }
    }

    /// Starts a accession claim in status idle.
    static func newAccessionClaim(_ code: String, name: String) -> AccessionClaim {
        return AccessionClaim(
            code: code,
            name: name,
            allergy: "",
            version: 0,
            segment: "",
            capacity: 0,
            diagnosisCode: "",
            timezone: "",
            copay: 0.0,
            status: AccessionClaimStatus.idle
        )
    }
}
