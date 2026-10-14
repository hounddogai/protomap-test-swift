import AcmePlatform
import Foundation

extension Consent {
    /// Where a revocation group is in its life cycle.
    enum RevocationGroupStatus: String, CaseIterable {
        case idle
        case warming
        case ready
        case draining
        case stopped
    }

    /// A revocation group as the revocation team keeps it.
    final class RevocationGroup {
        var code: String
        var label: String
        var diagnosisCode: String
        var quantity: Int
        var ward: String
        var retries: Int
        var cost: Double
        var createdAt: Int
        var status: RevocationGroupStatus

        init(code: String, label: String, diagnosisCode: String, quantity: Int, ward: String, retries: Int, cost: Double, createdAt: Int, status: RevocationGroupStatus) {
            self.code = code
            self.label = label
            self.diagnosisCode = diagnosisCode
            self.quantity = quantity
            self.ward = ward
            self.retries = retries
            self.cost = cost
            self.createdAt = createdAt
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

        func canMoveTo(_ next: RevocationGroupStatus) -> Bool {
            switch status {
            case .idle:
                switch next {
                case .ready:
                    return true
                default:
                    break
                }
                return false
            case .warming:
                switch next {
                case .ready, .stopped:
                    return true
                default:
                    break
                }
                return false
            case .ready:
                return next == RevocationGroupStatus.draining || next == RevocationGroupStatus.stopped
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

        func moveTo(_ next: RevocationGroupStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("revocation group \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
            createdAt = Int(Date().timeIntervalSince1970)
        }

        func displayLabel() -> String {
            return "\(code) (\(label))"
        }

        func adjustedValue() -> Double {
            return ((Double(createdAt) + Double(retries)) * 100).rounded() / 100
        }

        func copyValue() -> RevocationGroup {
            return RevocationGroup(
                code: code,
                label: label,
                diagnosisCode: diagnosisCode,
                quantity: quantity,
                ward: ward,
                retries: retries,
                cost: cost,
                createdAt: createdAt,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(ward)
        }
    }

    /// Starts a revocation group in status idle.
    static func newRevocationGroup(_ code: String, label: String) -> RevocationGroup {
        return RevocationGroup(
            code: code,
            label: label,
            diagnosisCode: "",
            quantity: 0,
            ward: "",
            retries: 0,
            cost: 0.0,
            createdAt: 0,
            status: RevocationGroupStatus.idle
        )
    }
}
