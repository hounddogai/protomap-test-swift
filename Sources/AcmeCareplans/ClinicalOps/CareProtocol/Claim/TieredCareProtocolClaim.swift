import AcmePlatform
import Foundation

extension ClinicalOps {
    /// Where a tiered care protocol claim is in its life cycle.
    enum TieredCareProtocolClaimStatus: String, CaseIterable {
        case idle
        case warming
        case ready
        case draining
        case stopped
    }

    /// A tiered care protocol claim as the care protocol team keeps it.
    final class TieredCareProtocolClaim {
        var code: String
        var label: String
        var procedureCode: String
        var attributes: [String: String]
        var specialty: String
        var category: String
        var reviewer: String
        var revision: Int
        var acuity: Int
        var facility: String
        var pinned: Bool
        var status: TieredCareProtocolClaimStatus

        init(code: String, label: String, procedureCode: String, attributes: [String: String], specialty: String, category: String, reviewer: String, revision: Int, acuity: Int, facility: String, pinned: Bool, status: TieredCareProtocolClaimStatus) {
            self.code = code
            self.label = label
            self.procedureCode = procedureCode
            self.attributes = attributes
            self.specialty = specialty
            self.category = category
            self.reviewer = reviewer
            self.revision = revision
            self.acuity = acuity
            self.facility = facility
            self.pinned = pinned
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

        func canMoveTo(_ next: TieredCareProtocolClaimStatus) -> Bool {
            switch status {
            case .idle:
                switch next {
                case .warming:
                    return true
                default:
                    break
                }
                return false
            case .warming:
                switch next {
                case .stopped:
                    return true
                default:
                    break
                }
                return false
            case .ready:
                switch next {
                case .stopped:
                    return true
                default:
                    break
                }
                return false
            case .draining:
                return next == TieredCareProtocolClaimStatus.stopped
            default:
                break
            }
            return false
        }

        func moveTo(_ next: TieredCareProtocolClaimStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("tiered care protocol claim \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
            revision += 1
        }

        func displayLabel() -> String {
            return "\(code) / \(label)"
        }

        func attribute(_ key: String, fallback: String) -> String {
            guard let found = attributes[key] else {
                return fallback
            }
            if found.trimmingCharacters(in: .whitespaces) == "" {
                return fallback
            }
            return found
        }

        func adjustedTotal() -> Double {
            return ((Double(revision) + Double(acuity)) * 100).rounded() / 100
        }

        func copyValue() -> TieredCareProtocolClaim {
            return TieredCareProtocolClaim(
                code: code,
                label: label,
                procedureCode: procedureCode,
                attributes: attributes,
                specialty: specialty,
                category: category,
                reviewer: reviewer,
                revision: revision,
                acuity: acuity,
                facility: facility,
                pinned: pinned,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(category)
        }
    }

    /// Starts a tiered care protocol claim in status idle.
    static func newTieredCareProtocolClaim(_ code: String, label: String) -> TieredCareProtocolClaim {
        return TieredCareProtocolClaim(
            code: code,
            label: label,
            procedureCode: "",
            attributes: [:],
            specialty: "",
            category: "",
            reviewer: "",
            revision: 0,
            acuity: 0,
            facility: "",
            pinned: false,
            status: TieredCareProtocolClaimStatus.idle
        )
    }
}
